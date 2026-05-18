---
name: nestjs-patterns
description: NestJS module structure, DTOs, services, controllers, guards, and custom decorators. Use when building or reviewing NestJS backend code.
---

# NestJS Patterns

## Module Structure

```
src/modules/users/
├── users.module.ts
├── users.controller.ts
├── users.service.ts
├── dto/
│   ├── create-user.dto.ts
│   └── update-user.dto.ts
└── guards/
    └── user-owner.guard.ts
```

## Module Definition

```typescript
@Module({
  imports: [PrismaModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

## DTOs with Validation

```typescript
import { IsEmail, IsString, MinLength } from 'class-validator'

export class CreateUserDto {
  @IsEmail()
  email: string

  @IsString()
  @MinLength(8)
  password: string
}
```

Pair with a global `ValidationPipe` (in `main.ts`):

```typescript
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,            // strip unknown fields
  forbidNonWhitelisted: true, // reject unknown fields
  transform: true,            // auto-cast types
}))
```

## Service Pattern

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUserDto) {
    return this.prisma.user.create({ data: dto })
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } })
    if (!user) throw new NotFoundException()
    return user
  }
}
```

## Controller Pattern

```typescript
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto)
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id)
  }
}
```

## Guards

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

@Injectable()
export class ResourceOwnerGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest()
    return request.user.id === request.params.id
  }
}
```

## Custom Decorators

```typescript
export const CurrentUser = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest()
    return data ? request.user?.[data] : request.user
  },
)

// Usage: @CurrentUser() user  OR  @CurrentUser('id') id
```

## Prisma Service (lifecycle)

```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect()
  }
}
```

## Forbidden Patterns

- Business logic in controllers (move to services)
- Returning sensitive fields (password, salt, refresh tokens) — use a response DTO
- Inputs without `class-validator` validation
- Injecting repositories directly into controllers — go through a service
- Hardcoded secrets — read from `ConfigService` / `process.env`
- Silent catch blocks
