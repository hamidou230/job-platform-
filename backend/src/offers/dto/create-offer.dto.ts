import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean, IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { OfferType, OfferStatus, ExperienceLevel } from '@prisma/client';

export class CreateOfferDto {
  @ApiProperty({ example: 'Stage Développeur Flutter' })
  @IsString() @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Nous recherchons un stagiaire motivé...' })
  @IsString() @IsNotEmpty()
  description: string;

  @ApiProperty({ enum: OfferType, example: 'INTERNSHIP' })
  @IsEnum(OfferType)
  type: OfferType;

  @ApiPropertyOptional({ example: 'Casablanca' })
  @IsOptional() @IsString()
  location?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional() @IsBoolean()
  isRemote?: boolean;

  @ApiPropertyOptional({ example: 4000 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0)
  salaryMin?: number;

  @ApiPropertyOptional({ example: 6000 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(0)
  salaryMax?: number;

  @ApiPropertyOptional({ example: 'Dart,Flutter,REST API' })
  @IsOptional() @IsString()
  requiredSkills?: string;

  @ApiPropertyOptional({ enum: ExperienceLevel, default: 'JUNIOR' })
  @IsOptional() @IsEnum(ExperienceLevel)
  experienceLevel?: ExperienceLevel;

  @ApiPropertyOptional({ enum: OfferStatus, default: 'OPEN' })
  @IsOptional() @IsEnum(OfferStatus)
  status?: OfferStatus;

  @ApiPropertyOptional({ example: '2026-09-01T00:00:00.000Z' })
  @IsOptional() @Type(() => Date)
  deadline?: Date;
}
