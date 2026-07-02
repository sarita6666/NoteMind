#  NoteMind App

Aplicación móvil desarrollada con **Flutter** que permite gestionar notas personales, comunicarse mediante un sistema de chat e interactuar con un asistente de inteligencia artificial. La aplicación integra múltiples servicios en la nube para ofrecer autenticación segura, almacenamiento de información y gestión de archivos multimedia.

---

# Descripción del Proyecto

**NoteMind App** es una aplicación móvil diseñada para facilitar la organización de información personal mediante notas inteligentes y herramientas de comunicación. Además de permitir la creación y administración de notas, incorpora un sistema de mensajería y un asistente basado en inteligencia artificial que mejora la productividad del usuario.

Como parte de su arquitectura, el proyecto integra diferentes servicios en la nube para aprovechar las fortalezas de cada plataforma:

- **Firebase Authentication** para la autenticación de usuarios.
- **Cloud Firestore** para el almacenamiento de información de la aplicación.
- **Supabase Storage** para almacenar imágenes y videos compartidos dentro de la aplicación.
- **Backend desarrollado en Node.js** encargado de la comunicación con la inteligencia artificial.

---

# Objetivo General

Desarrollar una aplicación móvil multiplataforma que permita gestionar notas, compartir contenido multimedia e interactuar con un asistente inteligente mediante una interfaz moderna, intuitiva y segura.

---

# Características Principales

- Registro e inicio de sesión.
- Gestión completa de notas.
- Edición y eliminación de notas.
- Compartir notas con otros usuarios.
- Chat en tiempo real.
- Chat con inteligencia artificial.
- Perfil de usuario personalizable.
- Envío de imágenes.
- Envío de videos.
- Almacenamiento seguro de archivos multimedia.
- Interfaz moderna y responsive.

---

# Tecnologías Utilizadas

## Desarrollo

- Flutter
- Dart

## Backend

- Node.js
- Express.js

## Base de Datos y Servicios

- Firebase Authentication
- Cloud Firestore
- Supabase Storage

## Inteligencia Artificial

- API de Inteligencia Artificial (Backend)

---

# Arquitectura del Proyecto

El proyecto sigue una estructura modular que facilita su mantenimiento, escalabilidad y reutilización del código.

```text
lib
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
│   │       chat_screen.dart
│   │
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

# Organización de Carpetas

### core

Contiene la configuración global de la aplicación, temas, colores y utilidades compartidas.

### models

Modelos de datos utilizados para representar usuarios, notas y mensajes.

### routes

Administración centralizada de las rutas de navegación.

### screens

Pantallas principales organizadas por módulos funcionales.

### services

Implementación de la lógica de negocio y comunicación con Firebase, Supabase y el backend.

### widgets

Componentes reutilizables personalizados utilizados en toda la aplicación.

---

# Requisitos Previos

Antes de ejecutar el proyecto es necesario contar con:

- Flutter SDK
- Dart SDK
- Node.js
- Android Studio o Visual Studio Code
- Emulador Android o dispositivo físico
- Proyecto de Firebase configurado
- Proyecto de Supabase configurado

---

# Instalación

## 1. Clonar el repositorio

```bash
git clone https://github.com/sarita6666/NoteMind-App.git
```

## 2. Entrar al proyecto

```bash
cd notemind_app
```

---

# Configuración del Backend

Ingresar a la carpeta del backend.

```bash
cd backend
```

Instalar dependencias.

```bash
npm install
```

Iniciar el servidor.

```bash
node app.js
```

---

# Ejecución de Flutter

Regresar a la carpeta principal.

```bash
cd ..
```

Actualizar Flutter.

```bash
flutter upgrade
```

Instalar dependencias.

```bash
flutter pub get
```

Ejecutar la aplicación.

```bash
flutter run
```

---

# Flujo General de la Aplicación

1. El usuario inicia sesión mediante Firebase Authentication.
2. La información personal y las notas se almacenan en Cloud Firestore.
3. Las imágenes y videos son almacenados en Supabase Storage.
4. El chat utiliza Firestore para sincronizar los mensajes.
5. El asistente inteligente se comunica mediante el backend desarrollado en Node.js.

---

# Integrante

**Sarita Gonzales Robayo**

---

# Información Académica

**Servicio Nacional de Aprendizaje (SENA)**

**Programa de Formación:** Análisis y Desarrollo de Software (ADSO)

**Ficha:** 3147272

---

# Repositorio

https://github.com/sarita6666/NoteMind-App
