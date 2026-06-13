import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateApplicationDto {
  @ApiProperty({ description: 'ID de l’offre' })
  @IsString() @IsNotEmpty()
  offerId: string;

  @ApiPropertyOptional({ description: 'Lettre de motivation' })
  @IsOptional() @IsString()
  coverLetter?: string;

  @ApiPropertyOptional({ description: 'URL du CV (sinon CV du profil)' })
  @IsOptional() @IsString()
  cvUrl?: string;
}
