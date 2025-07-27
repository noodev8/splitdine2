import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('adminToken');
  const pathname = request.nextUrl.pathname;
  
  // Handle paths - Next.js automatically strips basePath from pathname
  const isLoginPage = pathname === '/login';

  if (!token && !isLoginPage) {
    // Next.js will automatically prepend basePath to the redirect URL
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (token && isLoginPage) {
    // Next.js will automatically prepend basePath to the redirect URL
    return NextResponse.redirect(new URL('/', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};