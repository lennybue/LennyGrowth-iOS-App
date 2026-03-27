import { prisma } from '../config/database.js'
import type { PaginatedResponse } from '../types/index.js'

// ─── Articles ─────────────────────────────────────────────────────────────────

function serializeArticle(article: any, isBookmarked = false) {
  return {
    id:             article.id,
    title:          article.title,
    summary:        article.summary,
    content:        article.content,
    author: {
      id:        'lennard',
      name:      article.authorName,
      bio:       article.authorBio   ?? null,
      avatarUrl: article.authorAvatarUrl ?? null,
    },
    publishedAt:    article.publishedAt.toISOString(),
    updatedAt:      article.updatedAt?.toISOString() ?? null,
    imageUrl:       article.imageUrl   ?? null,
    tags:           article.tags,
    category:       article.category,
    readTimeMinutes: article.readTimeMinutes,
    sourceUrl:      article.sourceUrl  ?? null,
    isFeatured:     article.isFeatured,
    isBookmarked,
  }
}

export async function getArticles(
  page: number,
  pageSize: number,
  category?: string,
  search?: string,
  userId?: string
): Promise<PaginatedResponse<ReturnType<typeof serializeArticle>>> {
  const where: any = { isPublished: true }
  if (category) where.category = category
  if (search) {
    where.OR = [
      { title:   { contains: search, mode: 'insensitive' } },
      { summary: { contains: search, mode: 'insensitive' } },
      { tags:    { has: search.toLowerCase() } },
    ]
  }

  const [articles, totalCount] = await Promise.all([
    prisma.article.findMany({
      where,
      orderBy: [{ isFeatured: 'desc' }, { publishedAt: 'desc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
      include: userId ? { bookmarks: { where: { userId } } } : undefined,
    }),
    prisma.article.count({ where }),
  ])

  const items = articles.map(a =>
    serializeArticle(a, userId ? (a as any).bookmarks?.length > 0 : false)
  )
  return { items, totalCount, currentPage: page, pageSize }
}

export async function getArticle(id: string, userId?: string) {
  const article = await prisma.article.findFirst({
    where: { id, isPublished: true },
    include: userId ? { bookmarks: { where: { userId } } } : undefined,
  })
  if (!article) throw Object.assign(new Error('Article not found'), { statusCode: 404 })
  return serializeArticle(article, userId ? (article as any).bookmarks?.length > 0 : false)
}

export async function toggleBookmark(userId: string, articleId: string) {
  const existing = await prisma.bookmark.findUnique({ where: { userId_articleId: { userId, articleId } } })
  if (existing) {
    await prisma.bookmark.delete({ where: { userId_articleId: { userId, articleId } } })
  } else {
    await prisma.bookmark.create({ data: { userId, articleId } })
  }
  return getArticle(articleId, userId)
}

export async function getBookmarkedArticles(userId: string) {
  const bookmarks = await prisma.bookmark.findMany({
    where: { userId },
    include: { article: true },
    orderBy: { createdAt: 'desc' },
  })
  return bookmarks.map(b => serializeArticle(b.article, true))
}

// ─── Products ─────────────────────────────────────────────────────────────────

function serializeProduct(product: any) {
  return {
    id:               product.id,
    name:             product.name,
    description:      product.description,
    shortDescription: product.shortDescription,
    price:            product.price ? parseFloat(product.price.toString()) : null,
    currency:         product.currency,
    isFree:           product.isFree,
    category:         product.category,
    imageUrl:         product.imageUrl  ?? null,
    downloadUrl:      product.downloadUrl ?? null,
    previewUrl:       product.previewUrl ?? null,
    tags:             product.tags,
    rating:           product.rating ? parseFloat(product.rating.toString()) : null,
    reviewCount:      product.reviewCount,
    downloadCount:    product.downloadCount,
    fileType:         product.fileType  ?? null,
    fileSize:         product.fileSize  ?? null,
    createdAt:        product.createdAt.toISOString(),
    updatedAt:        product.updatedAt?.toISOString() ?? null,
    isNew:            product.isNew,
    isFeatured:       product.isFeatured,
  }
}

export async function getProducts(
  page: number,
  pageSize: number,
  category?: string,
  isFree?: boolean
): Promise<PaginatedResponse<ReturnType<typeof serializeProduct>>> {
  const where: any = { isPublished: true }
  if (category !== undefined) where.category = category
  if (isFree   !== undefined) where.isFree   = isFree

  const [products, totalCount] = await Promise.all([
    prisma.product.findMany({
      where,
      orderBy: [{ isFeatured: 'desc' }, { createdAt: 'desc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
    prisma.product.count({ where }),
  ])

  return { items: products.map(serializeProduct), totalCount, currentPage: page, pageSize }
}

export async function getProduct(id: string) {
  const product = await prisma.product.findFirst({ where: { id, isPublished: true } })
  if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 })
  return serializeProduct(product)
}

export async function trackDownload(userId: string, productId: string): Promise<{ downloadUrl: string; expiresAt: string | null }> {
  const product = await prisma.product.findFirst({ where: { id: productId, isPublished: true } })
  if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 })

  // Record download (upsert: tracks first download only)
  await prisma.download.upsert({
    where: { userId_productId: { userId, productId } },
    create: { userId, productId },
    update: { downloadedAt: new Date() },
  })

  // Increment counter
  await prisma.product.update({
    where: { id: productId },
    data: { downloadCount: { increment: 1 } },
  })

  return {
    downloadUrl: product.downloadUrl ?? '',
    expiresAt:   null,
  }
}

export async function getUserDownloads(userId: string) {
  const downloads = await prisma.download.findMany({
    where: { userId },
    include: { product: true },
    orderBy: { downloadedAt: 'desc' },
  })
  return downloads.map(d => ({
    productId:    d.productId,
    downloadedAt: d.downloadedAt.toISOString(),
    product:      serializeProduct(d.product),
  }))
}
