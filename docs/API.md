# API Documentation

## Overview

The SaaS Boilerplate provides a RESTful JSON API for programmatic access to all resources. The API is versioned and currently at v1.

**Base URL:** `https://api.yourdomain.com/api/v1`

## Authentication

### JWT Authentication

For mobile apps and SPAs, use JWT token authentication.

#### Login

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your_password"
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "expires_at": "2024-02-15T12:00:00Z"
}
```

#### Using the Token

Include the token in the Authorization header:

```http
GET /api/v1/users/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key Authentication

For server-to-server integrations, use API key authentication.

```http
GET /api/v1/users
X-API-Key: your_api_key_here
```

## Rate Limiting

API requests are rate limited to prevent abuse:

- **Authenticated requests:** 1000 requests per hour
- **Unauthenticated requests:** 100 requests per hour

Rate limit headers are included in all responses:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1705315200
```

## Pagination

List endpoints support pagination:

```http
GET /api/v1/users?page=2&per_page=25
```

Pagination info is included in response headers:

```
X-Total-Count: 150
X-Total-Pages: 6
X-Current-Page: 2
X-Per-Page: 25
Link: <...?page=1>; rel="first", <...?page=3>; rel="next", <...?page=1>; rel="prev", <...?page=6>; rel="last"
```

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "has already been taken"
      }
    ]
  }
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation error) |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |

## Endpoints

### Authentication

#### POST /api/v1/auth/login

Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "expires_at": "2024-02-15T12:00:00Z"
}
```

#### POST /api/v1/auth/logout

Invalidate current token.

**Response (204):** No content

#### POST /api/v1/auth/refresh

Refresh expiring token.

**Response (200):**
```json
{
  "token": "new_jwt_token",
  "expires_at": "2024-02-15T12:00:00Z"
}
```

### Users

#### GET /api/v1/users/me

Get current authenticated user.

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "confirmed_at": "2024-01-15T10:00:00Z",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

#### PATCH /api/v1/users/me

Update current user profile.

**Request:**
```json
{
  "user": {
    "first_name": "Jane",
    "last_name": "Smith"
  }
}
```

#### PUT /api/v1/users/me/password

Change password.

**Request:**
```json
{
  "current_password": "old_password",
  "password": "new_password",
  "password_confirmation": "new_password"
}
```

### Accounts

#### GET /api/v1/accounts

List accounts the current user belongs to.

**Response:**
```json
{
  "accounts": [
    {
      "id": "uuid",
      "name": "Acme Inc",
      "slug": "acme",
      "subscription_status": "active",
      "plan": "pro",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### GET /api/v1/accounts/:id

Get account details.

#### PATCH /api/v1/accounts/:id

Update account (requires owner/admin role).

**Request:**
```json
{
  "account": {
    "name": "New Name"
  }
}
```

### Members

#### GET /api/v1/accounts/:account_id/members

List account members.

**Response:**
```json
{
  "members": [
    {
      "id": "uuid",
      "user": {
        "id": "uuid",
        "email": "member@example.com",
        "first_name": "Team",
        "last_name": "Member"
      },
      "role": "member",
      "joined_at": "2024-01-15T00:00:00Z"
    }
  ]
}
```

#### POST /api/v1/accounts/:account_id/members

Invite new member.

**Request:**
```json
{
  "invitation": {
    "email": "newmember@example.com",
    "role": "member"
  }
}
```

#### PATCH /api/v1/accounts/:account_id/members/:id

Update member role.

**Request:**
```json
{
  "member": {
    "role": "admin"
  }
}
```

#### DELETE /api/v1/accounts/:account_id/members/:id

Remove member from account.

### Notifications

#### GET /api/v1/notifications

List notifications for current user.

**Query Parameters:**
- `read`: Filter by read status (true/false)
- `type`: Filter by notification type

**Response:**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "invitation_accepted",
      "title": "Invitation Accepted",
      "body": "John Doe accepted your invitation",
      "read_at": null,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### PATCH /api/v1/notifications/:id/read

Mark notification as read.

#### POST /api/v1/notifications/mark_all_read

Mark all notifications as read.

### Billing

#### GET /api/v1/accounts/:account_id/subscription

Get current subscription details.

**Response:**
```json
{
  "subscription": {
    "plan": "pro",
    "status": "active",
    "current_period_start": "2024-01-01T00:00:00Z",
    "current_period_end": "2024-02-01T00:00:00Z",
    "cancel_at_period_end": false
  }
}
```

#### POST /api/v1/accounts/:account_id/subscription/checkout

Create checkout session for subscription change.

**Request:**
```json
{
  "plan": "enterprise"
}
```

**Response:**
```json
{
  "checkout_url": "https://checkout.stripe.com/..."
}
```

#### POST /api/v1/accounts/:account_id/subscription/portal

Get customer portal URL.

**Response:**
```json
{
  "portal_url": "https://billing.stripe.com/..."
}
```

### API Keys

#### GET /api/v1/api_keys

List API keys for current account.

#### POST /api/v1/api_keys

Create new API key.

**Request:**
```json
{
  "api_key": {
    "name": "Production Key"
  }
}
```

**Response:**
```json
{
  "api_key": {
    "id": "uuid",
    "name": "Production Key",
    "key": "sk_live_...",
    "created_at": "2024-01-15T00:00:00Z"
  }
}
```

Note: The full key is only returned on creation. Store it securely.

#### DELETE /api/v1/api_keys/:id

Revoke API key.

## Webhooks

### Webhook Events

Your application can receive webhook notifications for various events:

| Event | Description |
|-------|-------------|
| `subscription.created` | New subscription created |
| `subscription.updated` | Subscription changed |
| `subscription.cancelled` | Subscription cancelled |
| `member.invited` | Team member invited |
| `member.joined` | Team member joined |
| `member.removed` | Team member removed |

### Webhook Payload

```json
{
  "event": "subscription.updated",
  "timestamp": "2024-01-15T10:00:00Z",
  "data": {
    "account_id": "uuid",
    "old_plan": "free",
    "new_plan": "pro"
  }
}
```

### Webhook Signature Verification

Webhooks include a signature header for verification:

```
X-Webhook-Signature: sha256=abc123...
```

Verify using:
```ruby
expected = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload_body)
Rack::Utils.secure_compare(expected, signature)
```

## SDKs & Libraries

### Ruby

```ruby
# Gemfile
gem 'saas_boilerplate_client'

# Usage
client = SaasBoilerplate::Client.new(api_key: 'your_key')
users = client.users.list
```

### JavaScript/TypeScript

```javascript
import { SaasBoilerplateClient } from 'saas-boilerplate-js';

const client = new SaasBoilerplateClient({ apiKey: 'your_key' });
const users = await client.users.list();
```

## Changelog

### v1 (Current)

- Initial API release
- Full CRUD for all resources
- JWT and API key authentication
- Webhook support
