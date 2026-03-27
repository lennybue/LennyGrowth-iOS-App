import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  // ─── Articles ──────────────────────────────────────────────────────────────

  const articles = [
    {
      title: 'On-Page SEO: Die 7 wichtigsten Rankingfaktoren 2026',
      summary: 'Entdecke die wichtigsten Rankingfaktoren und optimiere deine Website für Top-Rankings.',
      content: `## Einleitung\n\nSEO ist kein Geheimnis – aber viele unterschätzen, wie präzise Google die Qualität einer Seite bewertet.\n\n## 1. E-E-A-T\n\nExpertise, Experience, Authoritativeness, Trustworthiness – zeige echte Erfahrung durch Case Studies und konkrete Daten.\n\n## 2. Core Web Vitals\n\n- **LCP**: < 2,5 Sekunden\n- **FID**: < 100 ms\n- **CLS**: < 0,1\n\n## 3. Semantische Struktur\n\nNutze H1–H6 sinnvoll. Verlinke intern auf relevante Unterseiten.\n\n## Fazit\n\nWer diese Faktoren konsequent umsetzt, hat einen signifikanten Vorteil gegenüber 90 % der Konkurrenz.`,
      category: 'seo',
      tags: ['seo', 'onpage', 'ranking'],
      readTimeMinutes: 7,
      isFeatured: true,
      publishedAt: new Date('2026-01-15'),
    },
    {
      title: 'Google Ads CPA senken: 5 bewährte Strategien',
      summary: 'Mit diesen Techniken reduzierst du deinen Cost-per-Acquisition nachhaltig.',
      content: `## Warum der CPA entscheidend ist\n\nEin hoher CPA vernichtet dein Budget. Diese 5 Strategien helfen dir, ihn zu senken.\n\n## 1. Negative Keywords\n\nDer schnellste ROI-Boost: Blockiere irrelevante Suchanfragen.\n\n## 2. Quality Score optimieren\n\nAnzeigenrelevanz, Landing Page Experience und CTR verbessern.\n\n## 3. Smart Bidding kalibrieren\n\nTarget CPA braucht min. 30 Conversions/Monat zum Lernen.\n\n## 4. Ad Scheduling\n\nSchalte Ads nur zu profitablen Zeiten.\n\n## 5. Audience Layering\n\nCombine In-Market Audiences mit Custom Intent.`,
      category: 'marketing',
      tags: ['google ads', 'sea', 'cpa'],
      readTimeMinutes: 6,
      isFeatured: false,
      publishedAt: new Date('2026-01-22'),
    },
    {
      title: 'KI-gestützte Marketing-Automatisierung: Praxisguide',
      summary: 'Wie KI dein Marketing effizienter macht – von Content bis Lead-Nurturing.',
      content: `## KI im Marketing-Alltag\n\nKI-Tools können 60 % der repetitiven Marketing-Aufgaben automatisieren.\n\n## Content-Erstellung\n\nMit Claude oder GPT-4 kannst du Drafts in Sekunden generieren – aber Editing ist Pflicht.\n\n## Lead-Nurturing\n\nKI-personalisierte E-Mail-Sequenzen steigern die Open Rate um 20-30 %.\n\n## SEO-Optimierung\n\nKI-Tools wie Clearscope oder Surfer SEO analysieren Top-10-Rankings und geben konkrete Empfehlungen.\n\n## Fazit\n\nKI ersetzt keine Strategie – aber es multipliziert deine Umsetzungsgeschwindigkeit.`,
      category: 'growth',
      tags: ['ki', 'automation', 'marketing'],
      readTimeMinutes: 10,
      isFeatured: true,
      publishedAt: new Date('2026-02-01'),
    },
    {
      title: 'Google Analytics 4: Die wichtigsten KPIs für E-Commerce',
      summary: 'Welche GA4-Metriken wirklich zählen und wie du sie richtig interpretierst.',
      content: `## GA4 für E-Commerce\n\nGA4 ist fundamental anders als UA. Diese KPIs solltest du täglich überwachen.\n\n## 1. Purchase Conversion Rate\n\nNicht Traffic – Conversion ist der entscheidende Metric.\n\n## 2. Revenue per User\n\nBesser als reiner Umsatz: zeigt echten Kundenwert.\n\n## 3. Engaged Sessions Rate\n\nGA4 verwendet Engagement statt Bounce Rate.\n\n## 4. ROAS by Channel\n\nWelcher Kanal liefert den besten Return?\n\n## Setup\n\nGA4 Enhanced E-Commerce Tracking korrekt einrichten ist Pflicht.`,
      category: 'analytics',
      tags: ['ga4', 'analytics', 'kpis', 'ecommerce'],
      readTimeMinutes: 8,
      isFeatured: false,
      publishedAt: new Date('2026-02-10'),
    },
    {
      title: 'Local SEO: Wie du in Google Maps ganz oben rankst',
      summary: 'Lokale Sichtbarkeit maximieren und mehr Kunden aus deiner Region gewinnen.',
      content: `## Local SEO ist unterschätzt\n\nFür lokale Businesses ist Google Maps oft der wichtigste Traffic-Kanal.\n\n## Google Business Profile\n\nVollständig ausfüllen: NAP, Öffnungszeiten, Fotos, Posts, Q&A.\n\n## Bewertungen\n\n4,0+ Sterne mit >50 Reviews ist das Ziel. Automatisiere die Review-Anfrage nach jedem Kauf.\n\n## Local Citations\n\nKonsistente Einträge in Branchenverzeichnissen (Yelp, Das Örtliche, Gelbe Seiten).\n\n## On-Page Local Signals\n\nLokale Keywords in Title Tags, H1 und Schema Markup.`,
      category: 'seo',
      tags: ['local seo', 'google maps', 'local marketing'],
      readTimeMinutes: 6,
      isFeatured: false,
      publishedAt: new Date('2026-02-18'),
    },
  ]

  for (const article of articles) {
    await prisma.article.upsert({
      where: { id: article.title.toLowerCase().replace(/[^a-z0-9]/g, '-').slice(0, 30) },
      create: {
        id: article.title.toLowerCase().replace(/[^a-z0-9]/g, '-').slice(0, 30),
        ...article,
        authorName: 'Lennard Büssow',
        authorBio: 'Digital Marketing Specialist & IT-Consultant | SEO · SEA · KI | DACH',
        imageUrl: `https://picsum.photos/seed/${Math.random().toString(36).slice(2, 7)}/800/450`,
        isPublished: true,
      },
      update: {},
    })
  }

  // ─── Products (Free Lead Magnets) ─────────────────────────────────────────

  const products = [
    {
      id: 'product-prompts-ki',
      name: '50+ KI-Prompts für Marketer',
      description: 'Die besten KI-Prompts für Content-Erstellung, SEO-Texte, Ad-Copies und mehr. Sofort einsatzbereit für ChatGPT und Claude.',
      shortDescription: 'Sofort einsatzbereit für ChatGPT & Claude',
      isFree: true,
      category: 'swipe_file',
      downloadUrl: 'https://growthbylenny.gumroad.com/l/ki-prompts',
      tags: ['ki', 'prompts', 'chatgpt', 'marketing'],
      downloadCount: 8240,
      rating: 4.9,
      reviewCount: 312,
      fileType: 'pdf',
      fileSize: 2 * 1024 * 1024,
      isFeatured: true,
    },
    {
      id: 'product-growth-playbook',
      name: 'AI Growth Playbook – 30 Tage Experimente',
      description: '30-Tage-Experiment-Plan für datengetriebenes Wachstum mit KI-Tools. Jeden Tag ein Experiment, jeden Tag messbare Ergebnisse.',
      shortDescription: '30-Tage Wachstums-Experimente mit KI',
      isFree: true,
      category: 'guide',
      downloadUrl: 'https://growthbylenny.gumroad.com/l/growth-playbook',
      tags: ['growth', 'ki', 'playbook'],
      downloadCount: 5120,
      rating: 4.7,
      reviewCount: 189,
      fileType: 'pdf',
      fileSize: 3 * 1024 * 1024,
      isFeatured: true,
    },
    {
      id: 'product-seo-checklist',
      name: 'SEO-Checkliste 2026',
      description: 'Vollständige On-Page und Off-Page SEO-Checkliste für maximale Sichtbarkeit in Google.',
      shortDescription: 'On-Page & Off-Page SEO kompakt',
      isFree: true,
      category: 'checklist',
      downloadUrl: 'https://growthbylenny.gumroad.com/l/seo-checkliste',
      tags: ['seo', 'checkliste', 'onpage'],
      downloadCount: 12300,
      rating: 4.8,
      reviewCount: 445,
      fileType: 'pdf',
      fileSize: 1024 * 1024,
      isFeatured: false,
    },
    {
      id: 'product-ads-audit',
      name: 'Google Ads Audit Template',
      description: 'Strukturiertes Template für einen vollständigen Google Ads Account Audit. Findet Budget-Verluste sofort.',
      shortDescription: 'Account-Audit leicht gemacht',
      isFree: true,
      category: 'template',
      downloadUrl: 'https://growthbylenny.gumroad.com/l/ads-audit',
      tags: ['google ads', 'audit', 'template'],
      downloadCount: 3200,
      rating: 4.6,
      reviewCount: 98,
      fileType: 'google_docs',
      fileSize: 512 * 1024,
      isFeatured: false,
      isNew: true,
    },
    {
      id: 'product-content-calendar',
      name: 'Content-Marketing-Kalender',
      description: 'Jahresplanung für deinen Content: Blog, LinkedIn, Threads, E-Mail – alles in einem übersichtlichen Template.',
      shortDescription: 'Jahresplanung für alle Kanäle',
      isFree: true,
      category: 'template',
      downloadUrl: 'https://growthbylenny.gumroad.com/l/content-kalender',
      tags: ['content', 'kalender', 'planung'],
      downloadCount: 6700,
      rating: 4.5,
      reviewCount: 231,
      fileType: 'google_docs',
      fileSize: 768 * 1024,
      isFeatured: false,
    },
  ]

  for (const product of products) {
    await prisma.product.upsert({
      where: { id: product.id },
      create: {
        ...product,
        currency: 'EUR',
        isPublished: true,
        isNew: (product as any).isNew ?? false,
      },
      update: {},
    })
  }

  console.log('✅ Database seeded successfully')
  console.log(`   ${articles.length} articles, ${products.length} products`)
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
