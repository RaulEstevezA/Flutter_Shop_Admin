# Flutter Shop Admin

Flutter Shop Admin is a Flutter app for managing an online store's product catalog and **stock**. Authenticated users can browse the inventory, edit each product's details, update available units and attach photos taken with the camera or picked from the gallery. All data is stored in a REST backend built with NestJS.

- 🇬🇧 **English version:**  
  [Full functional app overview (English)](./README_en.md)

- 🇪🇸 **Versión en español:**  
  [Resumen completo de la app funcional (Español)](./README_es.md)

## Project Summary

This project was built as part of Fernando Herrera's **"Flutter de Cero a Experto"** course.

The app follows a Clean Architecture approach with a clear separation between domain, infrastructure and presentation layers. Its core is an **authenticated CRUD flow**: the user logs in with a JWT, the token is persisted locally and sent as a `Bearer` header on every product request. Products are loaded with infinite pagination, edited through a validated form (name, slug, price, **stock**, sizes, gender, description and tags) and saved back to the API, uploading any new photos first.

## Main Technologies

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform application framework |
| Riverpod | State management |
| Go Router | Declarative navigation with auth-based redirects |
| Dio | HTTP client for the REST API |
| Formz | Form input validation |
| image_picker | Camera and gallery access |
| shared_preferences | Local persistence of the session token |
| flutter_dotenv | Environment variable loading |
| flutter_staggered_grid_view | Masonry layout for the product catalog |
| google_fonts | Montserrat Alternates typography, bundled locally |

## Features

- Login and user registration with validated forms.
- Persistent session: the JWT is stored locally and verified on startup.
- Automatic redirects between login, splash and catalog based on authentication status.
- Product catalog in a 2-column masonry grid with infinite scroll.
- Product editor with validation for name, slug, price and **stock**.
- **Stock control**: available units are edited per product and validated as non-negative integers before saving.
- Size (XS–XXXL) and gender (men / women / kid) selectors.
- Photos from the camera or gallery, uploaded to the backend when the product is saved.
- Create and update products through the same endpoint flow (`POST` / `PATCH`).
- Permission prompts localized in English and Spanish on iOS

## Backend

The app needs the course's REST API running:

[Backend - Nest RestServer (Docker)](https://hub.docker.com/repository/docker/klerith/flutter-backend-teslo-shop/general)

Follow the backend guide to run it locally before starting the app.

## Setup

1. Start the backend.
2. Copy `.env.template` to `.env` and set the API URL:

```env
API_URL=http://localhost:3000/api
```

> On the Android emulator, `localhost` points to the emulator itself; use `http://10.0.2.2:3000/api` instead.

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Developer

**Raul Estevez**

- [Personal Website](https://raulesteveza.github.io/)
- [LinkedIn Profile](https://www.linkedin.com/in/raulesteveza/)
