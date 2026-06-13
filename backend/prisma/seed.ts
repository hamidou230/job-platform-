import { PrismaClient, Role, OfferType, ExperienceLevel } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const pass = await bcrypt.hash('Password123', 10);

  // Admin
  await prisma.user.upsert({
    where: { email: 'admin@jobplatform.ma' },
    update: {},
    create: { email: 'admin@jobplatform.ma', password: pass, role: Role.ADMIN },
  });

  // Entreprise
  const company = await prisma.user.upsert({
    where: { email: 'rh@techcorp.ma' },
    update: {},
    create: {
      email: 'rh@techcorp.ma',
      password: pass,
      role: Role.COMPANY,
      company: {
        create: {
          name: 'TechCorp',
          description: 'Société de développement logiciel.',
          industry: 'Informatique',
          location: 'Casablanca',
          size: '50-200',
        },
      },
    },
    include: { company: true },
  });

  // Étudiant
  await prisma.user.upsert({
    where: { email: 'etudiant@example.com' },
    update: {},
    create: {
      email: 'etudiant@example.com',
      password: pass,
      role: Role.STUDENT,
      student: {
        create: {
          firstName: 'Yassine',
          lastName: 'El Amrani',
          university: 'ENSA',
          fieldOfStudy: 'Génie Informatique',
          graduationYear: 2026,
          skills: 'Flutter,Dart,NestJS,MySQL',
        },
      },
    },
  });

  // Offres
  const offers = [
    {
      title: 'Stage Développeur Flutter',
      description: 'Développement d’applications mobiles avec Flutter et Riverpod.',
      type: OfferType.INTERNSHIP,
      location: 'Casablanca',
      salaryMin: 3000,
      salaryMax: 5000,
      requiredSkills: 'Flutter,Dart,REST API',
      experienceLevel: ExperienceLevel.JUNIOR,
    },
    {
      title: 'Développeur Backend NestJS',
      description: 'Conception d’APIs REST avec NestJS, Prisma et MySQL.',
      type: OfferType.JOB,
      location: 'Rabat',
      isRemote: true,
      salaryMin: 8000,
      salaryMax: 14000,
      requiredSkills: 'NestJS,TypeScript,MySQL,Prisma',
      experienceLevel: ExperienceLevel.INTERMEDIATE,
    },
    {
      title: 'Alternance Data Analyst',
      description: 'Analyse de données et reporting.',
      type: OfferType.ALTERNANCE,
      location: 'Marrakech',
      requiredSkills: 'SQL,Python,Power BI',
      experienceLevel: ExperienceLevel.JUNIOR,
    },
  ];

  for (const o of offers) {
    await prisma.offer.create({ data: { ...o, companyId: company.company!.id } });
  }

  console.log('✅ Seed terminé. Comptes: admin@jobplatform.ma / rh@techcorp.ma / etudiant@example.com (mdp: Password123)');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
