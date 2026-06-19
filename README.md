# NoteMind App

Aplicación móvil desarrollada en Flutter orientada a la gestión inteligente de notas y comunicación interactiva mediante herramientas de inteligencia artificial. El proyecto integra autenticación de usuarios, almacenamiento de información y funcionalidades de chat para ofrecer una experiencia moderna y dinámica.

---

# Descripción del Proyecto

NoteMind App es una aplicación diseñada para facilitar la organización de notas personales y la interacción mediante un sistema de chat integrado con inteligencia artificial. El proyecto fue desarrollado como parte del proceso formativo del SENA, aplicando buenas prácticas de desarrollo de software, modularización y separación de responsabilidades.

La aplicación permite a los usuarios:

- Registrarse e iniciar sesión.
- Crear y administrar notas.
- Utilizar un chat con inteligencia artificial.
- Gestionar información de perfil.
- Interactuar mediante un sistema de mensajería.

---

# Objetivo General

Desarrollar una aplicación móvil multiplataforma que permita gestionar notas y utilizar herramientas de inteligencia artificial mediante una interfaz moderna, intuitiva y funcional.

---

# Tecnologías Utilizadas

- Flutter
- Dart
- Firebase
- Node.js
- Express.js

---

# Funcionalidades Principales

- Sistema de autenticación de usuarios.
- Registro e inicio de sesión.
- Gestión de notas.
- Chat con inteligencia artificial.
- Sistema de mensajería.
- Gestión de perfil de usuario.
- Interfaz moderna y responsive.

---

# Arquitectura del Proyecto

El proyecto se encuentra organizado por módulos y capas para facilitar el mantenimiento y la escalabilidad.

## Estructura del Proyecto

```plaintext
C:.
│   firebase_options.dart
│   main.dart
│
├───core
│   ├───theme
│   │       app_colors.dart
│   │       app_text_styles.dart
│   │
│   └───utils
│           validators.dart
│
├───models
│       message_model.dart
│       note_model.dart
│       user_model.dart
│
├───routes
│       app_routes.dart
│
├───screens
│   ├───auth
│   │       login_screen.dart
│   │       register_screen.dart
│   │
│   ├───chat
│   │   │   chat_screen.dart
│   │   │
│   │   └───screens
│   │       └───chat
│   ├───chat_ai
│   │       chat_ai_screen.dart
│   │
│   ├───home
│   │       home_screen.dart
│   │
│   ├───notes
│   │       notes_screen.dart
│   │
│   └───profile
│           profile_screen.dart
│
├───services
│       ai_service.dart
│       auth_service.dart
│       chat_service.dart
│       note_service.dart
│       user_service.dart
│
└───widgets
        card_option.dart
        custom_alert.dart
        custom_bottom_nav.dart
        custom_button.dart
        custom_input.dart
        grid_options.dart
```

---

# Requisitos Previos

Antes de ejecutar el proyecto es necesario tener instalado:

- Flutter SDK
- Dart SDK
- Node.js
- Android Studio o VS Code
- Emulador Android o dispositivo físico
- Firebase configurado

---

# Instalación y Ejecución

## 1. Clonar el repositorio

```bash
git clone https://github.com/sarita6666/NoteMind-App.git
```

---

## 2. Ingresar a la carpeta del proyecto

```bash
cd notemind_app
```

---

## 3. Configurar y ejecutar el backend

Ingresar a la carpeta backend:

```bash
cd backend
```

Instalar dependencias:

```bash
npm install
```

Ejecutar servidor:

```bash
node app.js
```

---

## 4. Ejecutar la aplicación Flutter

Regresar a la raíz del proyecto:

```bash
cd ..
```

Actualizar Flutter:

```bash
flutter upgrade
```

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar aplicación:

```bash
flutter run
```

---

# Organización del Código

## core
Contiene configuraciones globales, estilos y utilidades.

## models
Modelos de datos utilizados en la aplicación.

## routes
Configuración de rutas y navegación.

## screens
Pantallas principales organizadas por módulos.

## services
Servicios encargados de la lógica y conexión con backend o Firebase.

## widgets
Componentes reutilizables personalizados.

---

# Integrante

- Sarita Gonzalez Robayo

---

# Información Académica

- Servicio Nacional de Aprendizaje SENA
- Ficha: 3147272
