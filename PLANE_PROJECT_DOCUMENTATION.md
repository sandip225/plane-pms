# Plane - Complete Project Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Applications](#3-applications)
4. [Packages](#4-packages)
5. [Technology Stack](#5-technology-stack)
6. [Authentication & Authorization](#6-authentication--authorization)
7. [API Structure](#7-api-structure)
8. [Database Models](#8-database-models)
9. [State Management](#9-state-management)
10. [UI Components](#10-ui-components)
11. [Deployment Options](#11-deployment-options)
12. [Configuration](#12-configuration)
13. [Features](#13-features)
14. [Development Guide](#14-development-guide)

---

## 1. Project Overview

**Plane** is an open-source project management tool for tracking issues, running cycles (sprints), and managing product roadmaps.

| Property | Value |
|----------|-------|
| Version | 1.2.0 |
| License | AGPL-3.0 |
| Repository | https://github.com/makeplane/plane.git |
| Node.js | 22.18.0+ |
| RAM Required | 12GB minimum |

### Key Highlights
- Open-source and self-hostable
- Modern UI with real-time collaboration
- Multiple deployment options (Docker, Kubernetes, EC2)
- OAuth support (Google, GitHub, GitLab, Gitea)
- Rich text editor with AI capabilities

---

## 2. Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                         NGINX PROXY                              │
│                    (SSL/TLS Termination)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   Web App     │     │  Admin App    │     │  Space App    │
│   (Port 3000) │     │  (Port 3001)  │     │  (Port 3002)  │
│   React/RR7   │     │   React/RR7   │     │   React/RR7   │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Server (Django)                         │
│                         Port 8000                                │
└─────────────────────────────────────────────────────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  PostgreSQL   │     │    Redis      │     │   RabbitMQ    │
│   Database    │     │    Cache      │     │  Message Queue│
└───────────────┘     └───────────────┘     └───────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   Celery Workers      │
                    │  (Background Tasks)   │
                    └───────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   MinIO / AWS S3      │
                    │   (File Storage)      │
                    └───────────────────────┘
```

### Monorepo Structure
```
plane/
├── apps/                    # Applications
│   ├── web/                 # Main web application
│   ├── admin/               # Admin/God-mode panel
│   ├── space/               # Public workspace sharing
│   ├── api/                 # Django REST API
│   ├── live/                # Real-time collaboration server
│   └── proxy/               # Nginx reverse proxy
├── packages/                # Shared libraries
│   ├── types/               # TypeScript definitions
│   ├── services/            # API client services
│   ├── shared-state/        # MobX state management
│   ├── ui/                  # React component library
│   ├── hooks/               # Custom React hooks
│   ├── constants/           # Application constants
│   ├── utils/               # Utility functions
│   ├── editor/              # Rich text editor
│   ├── i18n/                # Internationalization
│   └── ...                  # Other packages
├── deployments/             # Deployment configurations
│   ├── aio/                 # All-in-one deployment
│   ├── cli/                 # CLI deployment tool
│   ├── kubernetes/          # K8s manifests
│   └── swarm/               # Docker Swarm configs
└── docs/                    # Documentation
```

---

## 3. Applications

### 3.1 Web App (`apps/web`)
**Purpose**: Main user-facing application

| Property | Value |
|----------|-------|
| Port | 3000 |
| Framework | React Router 7 |
| Path | `/` |

**Features**:
- Work items (issues) management
- Cycles (sprints) tracking
- Modules management
- Views and filtering (List, Kanban, Calendar, Gantt, Spreadsheet)
- Pages (documentation/wiki)
- Analytics dashboard
- Drag-and-drop interface

**Directory Structure**:
```
apps/web/
├── app/                     # React Router routes
├── ce/                      # Community Edition components
├── ee/                      # Enterprise Edition components
├── core/                    # Core business logic
├── helpers/                 # Utility functions
└── public/                  # Static assets
```

### 3.2 Admin App (`apps/admin`)
**Purpose**: Instance administration (God Mode)

| Property | Value |
|----------|-------|
| Port | 3001 |
| Framework | React Router 7 |
| Path | `/god-mode` |

**Features**:
- Instance-level settings
- User management
- Workspace management
- System configuration
- License management

### 3.3 Space App (`apps/space`)
**Purpose**: Public workspace sharing

| Property | Value |
|----------|-------|
| Port | 3002 |
| Framework | React Router 7 (SSR) |
| Path | `/spaces` |

**Features**:
- Public issue viewing
- Guest access to workspaces
- Public project pages
- Shared views

### 3.4 API App (`apps/api`)
**Purpose**: Backend REST API

| Property | Value |
|----------|-------|
| Port | 8000 |
| Framework | Django + DRF |
| Database | PostgreSQL 15.7 |

**Directory Structure**:
```
apps/api/
├── plane/
│   ├── api/                 # API v1 endpoints
│   ├── app/                 # Legacy endpoints
│   ├── authentication/      # Auth handlers
│   ├── bgtasks/             # Celery background tasks
│   ├── db/                  # Database models
│   ├── license/             # Instance licensing
│   ├── middleware/          # Custom middleware
│   ├── space/               # Public API endpoints
│   └── web/                 # Web routes
└── bin/                     # Docker entrypoints
```

### 3.5 Live App (`apps/live`)
**Purpose**: Real-time collaborative editing

| Property | Value |
|----------|-------|
| Port | 3100 |
| Framework | Node.js + Hocuspocus |
| Path | `/live` |

**Features**:
- Real-time document sync
- Collaborative rich text editing
- WebSocket communication
- CRDT (Yjs) for conflict resolution

### 3.6 Proxy App (`apps/proxy`)
**Purpose**: Reverse proxy and load balancer

| Property | Value |
|----------|-------|
| Ports | 80, 443 |
| Framework | Nginx |

**Routing**:
```
/              → web:3000
/god-mode/*    → admin:3000
/spaces/*      → space:3000
/api/*         → api:8000
/auth/*        → api:8000
/live/*        → live:3000
/uploads/*     → minio:9000
```

---

## 4. Packages

| Package | Purpose |
|---------|---------|
| `@plane/types` | TypeScript type definitions |
| `@plane/services` | API client services |
| `@plane/shared-state` | MobX state management |
| `@plane/ui` | React component library |
| `@plane/hooks` | Custom React hooks |
| `@plane/constants` | Application constants |
| `@plane/utils` | Utility functions |
| `@plane/editor` | Rich text editor (Tiptap) |
| `@plane/i18n` | Internationalization (20+ languages) |
| `@plane/propel` | Portal/wrapper components |
| `@plane/logger` | Logging utilities |
| `@plane/decorators` | Python decorators |
| `@plane/codemods` | Code transformations |
| `@plane/eslint-config` | Shared ESLint config |
| `@plane/tailwind-config` | Shared Tailwind config |
| `@plane/typescript-config` | Shared TypeScript config |

---

## 5. Technology Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.3.1 | UI framework |
| React Router | 7.12.0 | Routing (SSR capable) |
| MobX | 6.12.0 | State management |
| Tailwind CSS | 3.4.0 | Styling |
| Tiptap | 2.22.3 | Rich text editor |
| Axios | 1.12.0 | HTTP client |
| SWR | 2.2.4 | Data fetching |
| Lucide React | 0.469.0 | Icons |
| date-fns | 4.1.0 | Date handling |

### Backend
| Technology | Version | Purpose |
|------------|---------|---------|
| Django | 4.x | Web framework |
| Django REST Framework | - | API framework |
| PostgreSQL | 15.7 | Database |
| Redis/Valkey | 7.2.11 | Cache |
| RabbitMQ | 3.13.6 | Message queue |
| Celery | - | Task queue |
| MinIO | - | File storage |

### DevOps
| Technology | Purpose |
|------------|---------|
| Docker | Containerization |
| Docker Compose | Local orchestration |
| Kubernetes | Production orchestration |
| Nginx | Reverse proxy |
| Let's Encrypt | SSL certificates |
| Turbo | Build system |
| pnpm | Package manager |

---

## 6. Authentication & Authorization

### Authentication Methods

1. **Email/Password**
   - Traditional sign-up/sign-in
   - Password reset via email

2. **Magic Links**
   - Passwordless authentication
   - Email-based one-time links

3. **OAuth Providers**
   - Google OAuth
   - GitHub OAuth
   - GitLab OAuth
   - Gitea OAuth

4. **API Keys**
   - Programmatic access
   - Rate limited (60/minute default)

### Authorization Roles

| Role | Level | Permissions |
|------|-------|-------------|
| Admin (20) | Workspace/Project | Full access |
| Member (15) | Workspace/Project | Read/Write |
| Guest (5) | Workspace/Project | Limited read |

### Auth Endpoints
```
POST /auth/sign-in/              # Email/password login
POST /auth/sign-up/              # Registration
POST /auth/magic-generate/       # Generate magic link
POST /auth/magic-sign-in/        # Magic link login
GET  /auth/google/               # Google OAuth
GET  /auth/github/               # GitHub OAuth
GET  /auth/gitlab/               # GitLab OAuth
GET  /auth/gitea/                # Gitea OAuth
POST /auth/forgot-password/      # Password reset
POST /auth/change-password/      # Change password
```

---

## 7. API Structure

### API Routes
```
/api/v1/          # Main API (versioned)
/api/             # Legacy endpoints
/api/public/      # Public/Space API
/auth/            # Authentication
/api/instances/   # Instance management
/api/schema/      # OpenAPI docs (Swagger/ReDoc)
```

### Key Endpoints

#### Workspaces
```
GET    /api/v1/workspaces/
POST   /api/v1/workspaces/
GET    /api/v1/workspaces/{slug}/
PATCH  /api/v1/workspaces/{slug}/
DELETE /api/v1/workspaces/{slug}/
GET    /api/v1/workspaces/{slug}/members/
```

#### Projects
```
GET    /api/v1/workspaces/{slug}/projects/
POST   /api/v1/workspaces/{slug}/projects/
GET    /api/v1/workspaces/{slug}/projects/{id}/
PATCH  /api/v1/workspaces/{slug}/projects/{id}/
DELETE /api/v1/workspaces/{slug}/projects/{id}/
```

#### Issues (Work Items)
```
GET    /api/v1/workspaces/{slug}/projects/{id}/issues/
POST   /api/v1/workspaces/{slug}/projects/{id}/issues/
GET    /api/v1/workspaces/{slug}/projects/{id}/issues/{issue_id}/
PATCH  /api/v1/workspaces/{slug}/projects/{id}/issues/{issue_id}/
DELETE /api/v1/workspaces/{slug}/projects/{id}/issues/{issue_id}/
```

#### Cycles
```
GET    /api/v1/workspaces/{slug}/projects/{id}/cycles/
POST   /api/v1/workspaces/{slug}/projects/{id}/cycles/
GET    /api/v1/workspaces/{slug}/projects/{id}/cycles/{cycle_id}/
PATCH  /api/v1/workspaces/{slug}/projects/{id}/cycles/{cycle_id}/
DELETE /api/v1/workspaces/{slug}/projects/{id}/cycles/{cycle_id}/
```

#### Modules
```
GET    /api/v1/workspaces/{slug}/projects/{id}/modules/
POST   /api/v1/workspaces/{slug}/projects/{id}/modules/
GET    /api/v1/workspaces/{slug}/projects/{id}/modules/{module_id}/
PATCH  /api/v1/workspaces/{slug}/projects/{id}/modules/{module_id}/
DELETE /api/v1/workspaces/{slug}/projects/{id}/modules/{module_id}/
```

---

## 8. Database Models

### Entity Relationship Overview
```
Workspace (1) ──────< (N) Project
    │                      │
    │                      ├──< Issue
    │                      │      ├──< IssueComment
    │                      │      ├──< IssueActivity
    │                      │      ├──< IssueAttachment
    │                      │      └──< IssueRelation
    │                      │
    │                      ├──< Cycle ──< CycleIssue
    │                      │
    │                      ├──< Module ──< ModuleIssue
    │                      │
    │                      ├──< State
    │                      │
    │                      ├──< Label
    │                      │
    │                      └──< Page
    │
    └──< WorkspaceMember ──> User
```

### Core Models

#### User
```python
- id (UUID)
- email (unique)
- username (unique)
- display_name
- first_name, last_name
- avatar, cover_image
- is_superuser
- date_joined
- last_location
```

#### Workspace
```python
- id (UUID)
- name
- slug (unique)
- logo
- owner (FK → User)
- created_at, updated_at
```

#### Project
```python
- id (UUID)
- name
- description
- identifier (e.g., "PROJ")
- network (Secret=0, Public=2)
- workspace (FK → Workspace)
- project_lead (FK → User)
- default_assignee (FK → User)
- created_at, updated_at
```

#### Issue
```python
- id (UUID)
- name
- description_html, description_stripped
- priority (Urgent, High, Medium, Low, None)
- state (FK → State)
- project (FK → Project)
- parent (FK → Issue, self-referential)
- assignees (M2M → User)
- labels (M2M → Label)
- start_date, target_date
- estimate_point
- sequence_id
- is_draft
- archived_at
- created_at, updated_at
```

#### Cycle
```python
- id (UUID)
- name
- description
- start_date, end_date
- project (FK → Project)
- owned_by (FK → User)
- is_active
- created_at, updated_at
```

#### Module
```python
- id (UUID)
- name
- description
- start_date, target_date
- project (FK → Project)
- lead (FK → User)
- members (M2M → User)
- created_at, updated_at
```

#### State
```python
- id (UUID)
- name
- color
- group (Backlog, Unstarted, Started, Completed, Cancelled, Triage)
- project (FK → Project)
- sequence
- is_default
```

---

## 9. State Management

### MobX Architecture
Location: `packages/shared-state`

**Key Stores**:
- `WorkspaceStore` - Workspace data and operations
- `ProjectStore` - Project management
- `IssueStore` - Issue CRUD and filtering
- `CycleStore` - Cycle management
- `ModuleStore` - Module management
- `UserStore` - User profile and preferences
- `ThemeStore` - UI theme settings
- `NotificationStore` - Notifications

**Pattern**:
```typescript
// Store definition
class IssueStore {
  issues = observable.map();
  
  @action
  fetchIssues = async (projectId: string) => {
    const response = await issueService.getIssues(projectId);
    runInAction(() => {
      this.issues.replace(response);
    });
  };
}

// Component usage
const IssueList = observer(() => {
  const { issueStore } = useStores();
  return <div>{issueStore.issues.map(...)}</div>;
});
```

---

## 10. UI Components

### Component Library (`@plane/ui`)
- Storybook available on port 6006
- Run: `pnpm --filter=@plane/ui storybook`

### Component Categories

**Form Components**:
- Input, Textarea
- Select, MultiSelect
- Checkbox, Radio
- DatePicker, TimePicker
- Toggle, Switch

**Layout Components**:
- Header, Sidebar
- Modal, Drawer
- Tabs, Accordion
- Card, Panel

**Data Display**:
- Table, List
- Avatar, Badge
- Tooltip, Popover
- Progress, Spinner

**Navigation**:
- Breadcrumb
- Menu, Dropdown
- Pagination

**Feedback**:
- Alert, Toast
- Loader, Skeleton

### Design System
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **Fonts**: Inter (variable), IBM Plex Mono
- **Themes**: Light/Dark mode support

---

## 11. Deployment Options

### Option 1: Docker Compose (Recommended)
```bash
# Clone repository
git clone https://github.com/makeplane/plane.git
cd plane

# Setup environment
cp .env.example .env
cp apps/api/.env.example apps/api/.env
# Edit both .env files

# Start services
docker-compose up -d
```

### Option 2: EC2 Deployment
```bash
# On EC2 instance
git clone https://github.com/makeplane/plane.git
cd plane

# Setup environment files
cp .env.example .env
cp apps/api/.env.example apps/api/.env

# Run deployment script
DOMAIN=your-domain.com EMAIL=your@email.com sudo -E bash deployments/ec2/deploy.sh
```

### Option 3: Kubernetes
```bash
cd deployments/kubernetes
# Apply manifests
kubectl apply -f .
```

### Option 4: All-in-One (AIO)
```bash
cd deployments/aio
docker-compose up -d
```

### Service Ports
| Service | Port |
|---------|------|
| Web | 3000 |
| Admin | 3001 |
| Space | 3002 |
| API | 8000 |
| Live | 3100 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| RabbitMQ | 5672 |
| MinIO | 9000 |
| Nginx | 80, 443 |

---

## 12. Configuration

### Root `.env`
```bash
# Database
POSTGRES_USER=plane
POSTGRES_PASSWORD=plane123
POSTGRES_DB=plane

# RabbitMQ
RABBITMQ_USER=plane
RABBITMQ_PASSWORD=plane123
RABBITMQ_VHOST=plane

# MinIO/S3
AWS_ACCESS_KEY_ID=minioaccess
AWS_SECRET_ACCESS_KEY=miniosecret
AWS_S3_BUCKET_NAME=uploads

# Ports
LISTEN_HTTP_PORT=80
LISTEN_HTTPS_PORT=443

# File upload limit (bytes)
FILE_SIZE_LIMIT=5242880
```

### API `.env` (`apps/api/.env`)
```bash
# Debug
DEBUG=0

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# Database
POSTGRES_USER=plane
POSTGRES_PASSWORD=plane123
POSTGRES_HOST=plane-db
POSTGRES_DB=plane
POSTGRES_PORT=5432
DATABASE_URL=postgresql://plane:plane123@plane-db:5432/plane

# Redis
REDIS_HOST=plane-redis
REDIS_PORT=6379
REDIS_URL=redis://plane-redis:6379/

# RabbitMQ
RABBITMQ_HOST=plane-mq
RABBITMQ_PORT=5672
RABBITMQ_USER=plane
RABBITMQ_PASSWORD=plane123
RABBITMQ_VHOST=plane

# S3/MinIO
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=minioaccess
AWS_SECRET_ACCESS_KEY=miniosecret
AWS_S3_ENDPOINT_URL=http://plane-minio:9000
AWS_S3_BUCKET_NAME=uploads
USE_MINIO=1

# URLs
WEB_URL=http://localhost
APP_BASE_URL=http://localhost:3000
ADMIN_BASE_URL=http://localhost:3001
SPACE_BASE_URL=http://localhost:3002
LIVE_BASE_URL=http://localhost:3100

# Paths
ADMIN_BASE_PATH=/god-mode
SPACE_BASE_PATH=/spaces
LIVE_BASE_PATH=/live

# Security
SECRET_KEY=your-secret-key
LIVE_SERVER_SECRET_KEY=live-secret-key

# Workers
GUNICORN_WORKERS=2
```

---

## 13. Features

### Work Items (Issues)
- ✅ Create, read, update, delete
- ✅ Rich text descriptions
- ✅ File attachments
- ✅ Comments with threading
- ✅ Activity/audit trail
- ✅ Issue relationships (blocked by, relates to, duplicates)
- ✅ Sub-issues (parent-child)
- ✅ Multiple assignees
- ✅ Labels and custom fields
- ✅ Priority levels (Urgent, High, Medium, Low, None)
- ✅ Story point estimates
- ✅ Reactions and voting
- ✅ Watchers/subscribers

### Views
- ✅ List view
- ✅ Kanban board
- ✅ Calendar view
- ✅ Gantt chart
- ✅ Spreadsheet view
- ✅ Saved views
- ✅ Advanced filtering
- ✅ Grouping (by state, priority, assignee, etc.)
- ✅ Sorting options

### Cycles (Sprints)
- ✅ Create and manage cycles
- ✅ Assign issues to cycles
- ✅ Burndown charts
- ✅ Progress tracking
- ✅ Archive cycles

### Modules
- ✅ Organize issues into modules
- ✅ Module progress tracking
- ✅ Module-specific views

### Pages (Documentation)
- ✅ Rich text editor
- ✅ Markdown support
- ✅ Collaborative editing
- ✅ Page hierarchy
- ✅ Sharing controls

### Collaboration
- ✅ Real-time editing
- ✅ Comments and discussions
- ✅ @mentions
- ✅ Activity feeds
- ✅ Notifications (in-app, email)
- ✅ Workspace invitations

### Analytics
- ✅ Real-time insights
- ✅ Burndown charts
- ✅ Velocity tracking
- ✅ Custom dashboards

### Integrations
- ✅ Webhooks
- ✅ API access
- ✅ OAuth providers
- ✅ S3-compatible storage

---

## 14. Development Guide

### Prerequisites
- Node.js 22.18.0+
- pnpm 10.24.0+
- Docker & Docker Compose
- 12GB RAM minimum

### Setup
```bash
# Clone
git clone https://github.com/makeplane/plane.git
cd plane

# Install dependencies
pnpm install

# Start development servers
pnpm dev
```

### Commands
| Command | Description |
|---------|-------------|
| `pnpm dev` | Start all dev servers |
| `pnpm build` | Build all packages |
| `pnpm check` | Run all checks |
| `pnpm check:lint` | ESLint |
| `pnpm check:types` | TypeScript |
| `pnpm fix` | Auto-fix issues |
| `pnpm fix:format` | Format code |

### Code Style
- **TypeScript**: Strict mode, all files typed
- **Naming**: camelCase (functions), PascalCase (components/types)
- **Imports**: `workspace:*` for internal, `catalog:` for external
- **Formatting**: Prettier with Tailwind plugin
- **Linting**: ESLint with shared config

### Testing
- Unit tests required for all features
- Run: `pnpm test`

### Component Development
```bash
# Start Storybook
pnpm --filter=@plane/ui storybook
# Opens on http://localhost:6006
```

---

## Quick Reference

### Docker Commands
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Remove volumes (reset data)
docker-compose down -v
```

### Troubleshooting

**Database connection failed**:
```bash
# Check if postgres is running
docker-compose ps plane-db

# Verify credentials match in both .env files
cat .env | grep POSTGRES
cat apps/api/.env | grep POSTGRES
```

**Proxy not starting**:
```bash
# Check proxy logs
docker logs proxy

# Rebuild proxy
docker-compose build --no-cache proxy
docker-compose up -d proxy
```

**Services not accessible**:
```bash
# Check all services
docker-compose ps

# Verify ports are open
sudo netstat -tlnp | grep -E '80|443|3000'
```

---

*Document generated for Plane v1.2.0*
