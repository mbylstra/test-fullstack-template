import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/shadcn/card';
import {
    Code,
    Database,
    FileJson,
    Smartphone,
    Globe,
    Zap,
    Rocket,
} from 'lucide-react';

export default function Home() {
    return (
        <div className="container mx-auto py-8 max-w-6xl">
            <div className="mb-12 text-center">
                <h1 className="text-4xl font-bold mb-4">Full-Stack Template</h1>
                <p className="text-gray-600 text-lg">
                    A product development template with TypeSpec API design,
                    React frontend, Flutter mobile app, and Python backend
                </p>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
                {/* API Design */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <FileJson className="w-8 h-8 text-blue-600" />
                            <div>
                                <CardTitle>API Design</CardTitle>
                                <CardDescription>
                                    TypeSpec 1.6.0
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        <p className="text-gray-700">
                            Platform-agnostic API contract defined in TypeSpec
                        </p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                            <li>Auto-generates OpenAPI specification</li>
                            <li>Generates Pydantic models for backend</li>
                            <li>Generates TypeScript client for frontend</li>
                        </ul>
                    </CardContent>
                </Card>

                {/* Web Frontend */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <Globe className="w-8 h-8 text-green-600" />
                            <div>
                                <CardTitle>Web Frontend</CardTitle>
                                <CardDescription>
                                    React + TypeScript
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        <p className="text-gray-700">
                            Modern React application with Tailwind CSS
                        </p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                            <li>Vite 7.x with Fast Refresh</li>
                            <li>shadcn/ui components</li>
                            <li>TypeScript 5.9 with strict mode</li>
                            <li>Hosted on Netlify</li>
                        </ul>
                    </CardContent>
                </Card>

                {/* Mobile App */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <Smartphone className="w-8 h-8 text-purple-600" />
                            <div>
                                <CardTitle>Mobile App</CardTitle>
                                <CardDescription>
                                    Flutter + Dart
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        <p className="text-gray-700">
                            Cross-platform mobile application
                        </p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                            <li>iOS and Android support</li>
                            <li>Shared codebase</li>
                            <li>Native performance</li>
                        </ul>
                    </CardContent>
                </Card>

                {/* Backend */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <Database className="w-8 h-8 text-orange-600" />
                            <div>
                                <CardTitle>Backend</CardTitle>
                                <CardDescription>
                                    FastAPI + PostgreSQL
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        <p className="text-gray-700">
                            Python backend with modern tooling
                        </p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                            <li>Python 3.12 managed by uv</li>
                            <li>SQLAlchemy 2.0 with Alembic</li>
                            <li>JWT authentication + Argon2</li>
                            <li>PostgreSQL 16 database</li>
                        </ul>
                    </CardContent>
                </Card>

                {/* Deployment */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <Rocket className="w-8 h-8 text-red-600" />
                            <div>
                                <CardTitle>Deployment</CardTitle>
                                <CardDescription>
                                    GitHub Actions + Digital Ocean
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        <p className="text-gray-700">
                            Automated CI/CD pipelines for seamless deployment
                        </p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                            <li>GitHub Actions workflows</li>
                            <li>Frontend deployed to Netlify</li>
                            <li>Backend deployed to Digital Ocean</li>
                            <li>Automated testing and builds</li>
                        </ul>
                    </CardContent>
                </Card>
            </div>

            {/* Key Features */}
            <Card className="mt-8">
                <CardHeader>
                    <div className="flex items-center gap-3">
                        <Zap className="w-8 h-8 text-yellow-600" />
                        <div>
                            <CardTitle>Key Features</CardTitle>
                            <CardDescription>
                                What makes this template special
                            </CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div>
                            <h3 className="font-semibold mb-2">
                                <Code className="w-4 h-4 inline mr-2" />
                                TypeSpec-First Design
                            </h3>
                            <p className="text-sm text-gray-600">
                                Define your API once in TypeSpec, automatically
                                generate client and server code for type-safe
                                development across all platforms
                            </p>
                        </div>
                        <div>
                            <h3 className="font-semibold mb-2">
                                <Database className="w-4 h-4 inline mr-2" />
                                Database Migrations
                            </h3>
                            <p className="text-sm text-gray-600">
                                Automatic database migrations with Alembic,
                                running seamlessly with Docker Compose or local
                                development
                            </p>
                        </div>
                        <div>
                            <h3 className="font-semibold mb-2">
                                <Zap className="w-4 h-4 inline mr-2" />
                                Developer Experience
                            </h3>
                            <p className="text-sm text-gray-600">
                                Hot reload, strict type checking, comprehensive
                                Makefiles, and modern package managers (uv for
                                Python, pnpm for Node)
                            </p>
                        </div>
                        <div>
                            <h3 className="font-semibold mb-2">
                                <Globe className="w-4 h-4 inline mr-2" />
                                Production Ready
                            </h3>
                            <p className="text-sm text-gray-600">
                                GitHub Actions CI/CD pipelines, Docker
                                configurations for development and production,
                                JWT authentication, deployment to Netlify
                                (frontend) and Digital Ocean (backend)
                            </p>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
