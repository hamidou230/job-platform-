import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateStudentDto {
  @ApiPropertyOptional() @IsOptional() @IsString() firstName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() lastName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() phone?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() university?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() fieldOfStudy?: string;

  @ApiPropertyOptional({ example: 2026 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1950) @Max(2100)
  graduationYear?: number;

  @ApiPropertyOptional() @IsOptional() @IsString() bio?: string;

  @ApiPropertyOptional({ example: 'Flutter,Dart,NestJS' })
  @IsOptional() @IsString() skills?: string;
}
