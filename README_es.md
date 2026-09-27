# Flutter Shop Admin - Resumen completo del proyecto

## Estado del Proyecto

**Snapshot actualizado:** `2026-09-28`  
**Rama:** `main`  
**Último commit documentado:** `266da21` - "Agregar archivo InfoPlist.swift para la configuración de la lista de propiedades"  
**Estado:** en desarrollo. Están implementados la autenticación, el catálogo, la edición de productos, el control de stock y la subida de fotos; quedan pendientes la búsqueda y el borrado de productos (ver [Trabajo Pendiente](#trabajo-pendiente)).

## Descripción General

Flutter Shop Admin es una aplicación Flutter para gestionar el catálogo y el stock de una tienda online. Consume una API REST hecha con NestJS y protegida con JWT, usa Clean Architecture, Riverpod como gestor de estado y Go Router para la navegación, con redirecciones según el estado de autenticación.

La parte técnica central de la app es el **CRUD autenticado**: el token de sesión se obtiene al hacer login, se guarda con `shared_preferences`, se vuelve a comprobar al arrancar y se envía en cada petición de productos. Los datos viajan de la API a la UI a través de datasources, mappers y repositorios, y de vuelta desde un formulario validado hacia la API, subiendo las fotos locales antes de guardar el producto.

## Tecnologías y Dependencias

**SDK:** Dart `>=2.19.4 <4.0.0` / Flutter (probado con Flutter `3.47.5`)

| Paquete | Versión | Uso |
|---|---:|---|
| flutter_riverpod | ^2.3.2 | Gestión de estado con `StateNotifierProvider` |
| go_router | ^6.2.0 | Navegación con `redirect` y `refreshListenable` |
| dio | ^5.0.2 | Cliente HTTP para las llamadas a la API |
| formz | 0.8.0 | Validación de campos de formulario |
| image_picker | ^1.2.3 | Fotos desde la cámara y la galería |
| shared_preferences | ^2.5.5 | Persistencia del token de sesión |
| flutter_dotenv | ^6.0.1 | Variables de entorno desde `.env` |
| flutter_staggered_grid_view | ^0.7.0 | `MasonryGridView` para el catálogo |
| google_fonts | ^8.2.1 | Tipografía Montserrat Alternates |
| path_provider | ^2.1.5 | Localización de directorios del sistema |
| flutter_lints | ^2.0.0 | Reglas de linting |

## Fuente de Datos

- **Backend:** [Backend - Nest RestServer (Docker)](https://hub.docker.com/repository/docker/klerith/flutter-backend-teslo-shop/general)
- **Base URL:** configurada en `.env` como `API_URL` (por ejemplo `http://localhost:3000/api`)
- **Autenticación:** JWT enviado en la cabecera `Authorization: Bearer <token>`
- **Imágenes:** servidas desde `{API_URL}/files/product/{imagen}`

La app no pasa las respuestas crudas de la API a la UI. `UserMapper` y `ProductMapper` convierten el JSON en las entidades `User` y `Product`. `ProductMapper` además convierte los nombres de imagen en URLs completas, y el formulario de producto hace el paso inverso antes de guardar, enviando a la API solo el nombre del archivo.

### Endpoints Utilizados

| Método | Endpoint | Propósito |
|---|---|---|
| `POST` | `/auth/login` | Login con email y contraseña |
| `POST` | `/auth/register` | Registro de un usuario nuevo |
| `GET` | `/auth/check-status` | Validar el token guardado y renovar la sesión |
| `GET` | `/products?limit=&offset=` | Listado paginado de productos |
| `GET` | `/products/{id}` | Detalle de un producto |
| `POST` | `/products` | Crear un producto |
| `PATCH` | `/products/{id}` | Actualizar un producto, incluido su stock |
| `POST` | `/files/product` | Subir una imagen de producto (`multipart/form-data`) |

### Gestión de Errores

| Caso | Resultado |
|---|---|
| `401` al hacer login | Mensaje del backend o "Credenciales incorrectas" |
| `400` al registrarse | Mensajes de validación del backend, unidos si llegan como lista |
| Timeout de conexión | "Revisar conexión a internet" |
| `401` al comprobar el token | Se cierra la sesión y se redirige al login |
| `404` al cargar un producto | Excepción `ProductNotFound` |

## Arquitectura

El proyecto está organizado por features, y cada feature sigue Clean Architecture:

```text
lib/
├── config/
│   ├── constants/        # Environment: carga el .env y expone API_URL
│   ├── router/           # GoRouter + GoRouterNotifier (redirecciones según la sesión)
│   └── theme/            # Material 3, color semilla #424CB8, Montserrat Alternates
└── features/
    ├── auth/
    │   ├── domain/           # Entidad User, contratos de datasource y repositorio
    │   ├── infrastructure/   # AuthDataSourceImpl (Dio), UserMapper, errores propios
    │   └── presentation/     # authProvider, formularios y pantallas de login/registro
    ├── products/
    │   ├── domain/           # Entidad Product, contratos de datasource y repositorio
    │   ├── infrastructure/   # ProductsDatasourceImpl, ProductMapper, ProductNotFound
    │   └── presentation/     # Providers, pantalla del catálogo, editor y ProductCard
    └── shared/
        ├── infrastructure/
        │   ├── inputs/       # Inputs de Formz: Email, Password, Title, Slug, Price, Stock...
        │   └── services/     # CameraGalleryService y KeyValueStorageService
        └── widgets/          # SideMenu, CustomProductField, FullScreenLoader...
```

### Flujo de Datos Autenticado

- `AuthNotifier` hace login o registro a través de `AuthRepository` y guarda el token con `KeyValueStorageService`.
- `productsRepositoryProvider` observa `authProvider` y construye `ProductsDatasourceImpl` con el token del usuario actual, así que todas las peticiones de Dio llevan la cabecera `Bearer`.
- Los datasources llaman a la API, los mappers convierten el JSON en entidades y los repositorios exponen métodos limpios a los providers.
- Los providers de Riverpod consumen los repositorios y entregan a la UI un estado listo para mostrar.

## Entidades del Dominio

| Entidad | Campos |
|---|---|
| User | `id`, `email`, `fullName`, `roles`, `token` (más el getter `isAdmin`) |
| Product | `id`, `title`, `price`, `description`, `slug`, `stock`, `sizes`, `gender`, `tags`, `images`, `user` |

## Features Implementados

### 1. Autenticación

`CheckAuthStatusScreen` es la ruta inicial (`/splash`) y muestra un loader mientras `AuthNotifier.checkAuthStatus()` lee el token guardado y lo valida contra `/auth/check-status`.

- **Login** (`/login`): email y contraseña validados con Formz. Se envía con el botón o desde el teclado.
- **Registro** (`/register`): nombre completo (mínimo 3 caracteres), email, contraseña (mínimo 6 caracteres, con mayúscula, minúscula y un número o símbolo) y confirmación de contraseña. La confirmación se vuelve a comprobar cada vez que cambia la contraseña.
- Mientras se envía el formulario, el botón queda desactivado (`isPosting`).
- Los errores del backend se muestran en un `SnackBar`.
- **Cerrar sesión** desde el menú lateral: se borra el token y el router vuelve al login.

### 2. Navegación Según la Sesión

`GoRouterNotifier` es un `ChangeNotifier` que escucha a `AuthNotifier` y se usa como `refreshListenable` del router. La función `redirect` aplica estas reglas:

| Estado | Comportamiento |
|---|---|
| `checking` | Se queda en `/splash` |
| `notAuthenticated` | Solo permite `/login` y `/register`; cualquier otra ruta redirige a `/login` |
| `authenticated` | `/login`, `/register` y `/splash` redirigen a `/` |

### 3. Catálogo de Productos

`ProductsScreen` muestra los productos en un `MasonryGridView` de 2 columnas. Cada `ProductCard` muestra la primera imagen con `FadeInImage` (con un loader animado como placeholder) y el nombre del producto; si no tiene imágenes, usa `assets/images/no-image.jpg`.

La paginación es infinita: el `ScrollController` llama a `loadNextPage()` cuando faltan 400 px para el final. `ProductsNotifier` pide páginas de 10 productos y usa los guards `isLoading` e `isLastPage` para evitar peticiones duplicadas.

Al tocar un producto se abre `/product/:id`, y el botón "Nuevo producto" abre `/product/new` para crear uno.

### 4. Editor de Productos

`ProductScreen` carga el producto con `productProvider` (`StateNotifierProvider.autoDispose.family`) y construye el formulario con `productFormProvider`, que recibe el `Product` como parámetro de la family.

| Campo | Validación |
|---|---|
| Nombre (`Title`) | Obligatorio |
| Slug | Obligatorio, sin espacios ni apóstrofes |
| Precio | Número mayor o igual a 0 |
| Existencias (stock) | Número entero mayor o igual a 0 |
| Tallas | Selección múltiple con `SegmentedButton` (XS, S, M, L, XL, XXL, XXXL) |
| Género | Selección única con iconos (men, women, kid) |
| Descripción | Texto libre multilínea |
| Tags | Texto separado por comas |

El botón de guardar marca todos los campos como tocados, comprueba que el formulario es válido y llama a `ProductsNotifier.createOrUpdateProduct()`. Si el producto ya estaba en la lista, lo sustituye; si no, lo añade. Un `SnackBar` confirma el guardado.

### 5. Control de Stock

El stock es el campo clave de inventario de cada producto:

- Se muestra y se edita en el campo "Existencias" del editor.
- El input `Stock` (Formz) rechaza valores vacíos, no numéricos y negativos, y el mensaje de error aparece bajo el campo.
- Al guardar, el valor se envía como `stock` en la petición `PATCH /products/{id}`, y el producto editado sustituye al anterior en `productsProvider`, así que el catálogo mantiene la cantidad nueva sin recargar.

### 6. Fotos de Producto

La app bar del editor tiene dos botones:

- **Galería** (`selectPhoto`) y **cámara** (`takePhoto`, cámara trasera), ambos a través de `CameraGalleryServiceImpl`, que usa `image_picker` con una calidad del 80 %.
- Las fotos nuevas se añaden al formulario y se ven al momento en la galería `PageView` (`FileImage` para archivos locales, `NetworkImage` para los remotos).
- Al guardar, `ProductsDatasourceImpl` separa las fotos nuevas (rutas locales) de las existentes, sube las nuevas en paralelo con `Future.wait` a `/files/product` y envía a la API la lista final de nombres.

### 7. Permisos Localizados (iOS)

Los diálogos de permisos de cámara, galería y micrófono tienen su descripción en `Info.plist` (inglés) y en `InfoPlist.strings` para `en` y `es`, así que se muestran en el idioma del dispositivo.

## Gestión de Estado

| Provider | Tipo | Propósito |
|---|---|---|
| authProvider | StateNotifierProvider<AuthNotifier, AuthState> | Estado de la sesión, usuario actual y mensajes de error |
| loginFormProvider | StateNotifierProvider.autoDispose | Estado del formulario de login |
| registerFormProvider | StateNotifierProvider.autoDispose | Estado del formulario de registro |
| goRouterNotifierProvider | Provider<GoRouterNotifier> | Puente entre la autenticación y el router |
| goRouterProvider | Provider<GoRouter> | Configuración del router |
| productsRepositoryProvider | Provider<ProductsRepository> | Repositorio con el token del usuario actual |
| productsProvider | StateNotifierProvider<ProductsNotifier, ProductsState> | Catálogo paginado y creación/actualización |
| productProvider | StateNotifierProvider.autoDispose.family<…, String> | Carga un producto por ID (o uno vacío para `new`) |
| productFormProvider | StateNotifierProvider.autoDispose.family<…, Product> | Formulario de producto con validación |

## Navegación

| Ruta | Pantalla | Acceso |
|---|---|---|
| `/splash` | `CheckAuthStatusScreen` | Ruta inicial mientras se comprueba la sesión |
| `/login` | `LoginScreen` | Solo sin sesión |
| `/register` | `RegisterScreen` | Solo sin sesión |
| `/` | `ProductsScreen` | Con sesión |
| `/product/:id` | `ProductScreen` | Con sesión; `new` crea un producto vacío |

## Configuración de Plataformas

| Plataforma | Configuración |
|---|---|
| iOS | Deployment target mínimo `15.0`; plugins mediante Swift Package Manager (sin CocoaPods) |
| Android | Gradle `9.1.0`, Android Gradle Plugin `9.0.1`, Kotlin `2.3.20` con el Kotlin integrado de AGP |

## Trabajo Pendiente

- **Búsqueda:** el botón de la lupa del catálogo todavía no tiene acción, y `searchProductByTerm` en el datasource lanza `UnimplementedError`.
- **Borrar productos:** todavía no hay opción de borrado.
- **Menú lateral:** el nombre de usuario está fijo ("Tony Stark") en lugar de usar el del usuario conectado.

## Setup

1. Arranca el [backend](https://hub.docker.com/repository/docker/klerith/flutter-backend-teslo-shop/general) siguiendo su guía.
2. Copia `.env.template` a `.env` y configura la URL:

```env
API_URL=http://localhost:3000/api
```

> En el emulador de Android, usa `http://10.0.2.2:3000/api`.

3. Instala las dependencias:

```bash
flutter pub get
```

4. Ejecuta la app:

```bash
flutter run
```

## README Principal

[Enlace al README.md principal](./README.md)
