import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsEnum, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'etudiant@example.com' })
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @ApiProperty({ example: 'Password123', minLength: 6 })
  @IsString()
  @MinLength(6, { message: 'Le mot de passe doit contenir au moins 6 caractères' })
  password: string;

  @ApiProperty({ enum: ['STUDENT', 'COMPANY'], example: 'STUDENT' })
  @IsEnum(Role, { message: 'Rôle invalide' })
  role: Role;

  // Champs étudiant
  @ApiProperty({ required: false, example: 'Yassine' })
  @IsOptional() @IsString() firstName?: string;

  @ApiProperty({ required: false, example: 'El Amrani' })
  @IsOptional() @IsString() lastName?: string;

  // Champs entreprise
  @ApiProperty({ required: false, example: 'TechCorp' })
  @IsOptional() @IsString() companyName?: string;
}
