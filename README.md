# 🌐 JetLeaf Web — HTTP Server & Web Framework

[![pub package](https://img.shields.io/badge/version-1.0.0-blue)](https://pub.dev/packages/jetleaf_web)
[![License](https://img.shields.io/badge/license-JetLeaf-green)](#license)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.9.0-blue)](https://dart.dev)

A comprehensive web framework for building HTTP servers, RESTful APIs, and dynamic web applications with JetLeaf.

## 📋 Overview

`jetleaf_web` provides everything needed to build production-grade web applications:

- **HTTP Server** — Multi-threaded server with keep-alive and compression
- **RESTful Routing** — Declarative route definition with `@RestController` and HTTP method annotations
- **Request/Response Handling** — Type-safe HTTP message processing
- **Content Negotiation** — Automatic format selection (JSON, XML, YAML, Form data)
- **HTTP Message Converters** — Built-in converters for common types
- **Multipart File Uploads** — Stream-based file handling
- **Exception Handling** — Centralized error resolution
- **Session Management** — HTTP session support with pluggable storage
- **Template Rendering** — Integration with JTL template engine
- **CORS & Security** — Cross-origin and CSRF protection

## 🚀 Quick Start

### Installation

Add `jetleaf_web` to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_core: ^1.0.0
  jetleaf_web: ^1.0.0
```

### Basic Web Application

```dart
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

// Define a REST controller
@RestController('/api/products')
class ProductController {
  final ProductService _service;

  @Autowired
  ProductController(this._service);

  // GET /api/products
  @GetMapping('/')
  Future<HttpResponse> listProducts() async {
    final products = await _service.getAllProducts();
    return HttpResponse.ok(products);
  }

  // GET /api/products/:id
  @GetMapping('/:id')
  Future<HttpResponse> getProduct(
    @PathVariable String id,
    HttpRequest request,
  ) async {
    final product = await _service.getProductById(id);
    if (product == null) {
      return HttpResponse.notFound();
    }
    return HttpResponse.ok(product);
  }

  // POST /api/products
  @PostMapping('/')
  Future<HttpResponse> createProduct(
    @RequestBody Product product,
    HttpRequest request,
  ) async {
    final created = await _service.createProduct(product);
    return HttpResponse.created(created);
  }

  // PUT /api/products/:id
  @PutMapping('/:id')
  Future<HttpResponse> updateProduct(
    @PathVariable String id,
    @RequestBody Product product,
    HttpRequest request,
  ) async {
    final updated = await _service.updateProduct(id, product);
    if (updated == null) {
      return HttpResponse.notFound();
    }
    return HttpResponse.ok(updated);
  }

  // DELETE /api/products/:id
  @DeleteMapping('/:id')
  Future<HttpResponse> deleteProduct(
    @PathVariable String id,
    HttpRequest request,
  ) async {
    await _service.deleteProduct(id);
    return HttpResponse.noContent();
  }
}

// Start the application
void main() async {
  final context = AnnotationConfigApplicationContext(['package:myapp']);
  final server = context.getPod<WebServer>();
  
  await server.start(port: 8080);
  print('🚀 Server running on http://localhost:8080');
}
```

## 🏗️ Architecture

### Request/Response Pipeline

```
HTTP Request
    ↓
Content Negotiation (Accept header)
    ↓
Route Matching
    ↓
Method Argument Resolution
    ↓
Controller Method Execution
    ↓
Return Value Handling
    ↓
HTTP Message Conversion
    ↓
HTTP Response
```

### Key Components

```
WebServer
├── RequestDispatcher
├── HandlerAdapter (method invocation)
├── ArgumentResolver (parameter injection)
├── ReturnValueHandler (response creation)
├── ContentNegotiationResolver
├── HttpMessageConverterRegistry
└── ExceptionResolver
```

## 📚 Key Features

### 1. Request Mapping

**Path-based routing**:

```dart
@RestController('/api/users')
class UserController {
  // GET /api/users
  @GetMapping('/')
  Future<HttpResponse> list() { }

  // GET /api/users/123
  @GetMapping('/:id')
  Future<HttpResponse> getById(@PathVariable String id) { }

  // POST /api/users
  @PostMapping('/')
  Future<HttpResponse> create(@RequestBody User user) { }

  // PUT /api/users/123
  @PutMapping('/:id')
  Future<HttpResponse> update(
    @PathVariable String id,
    @RequestBody User user,
  ) { }

  // DELETE /api/users/123
  @DeleteMapping('/:id')
  Future<HttpResponse> delete(@PathVariable String id) { }
}
```

### 2. Parameter Resolution

**Extract data from requests**:

```dart
@RestController('/api')
class DataController {
  // Path variables
  @GetMapping('/users/:userId/posts/:postId')
  Future<HttpResponse> getPost(
    @PathVariable String userId,
    @PathVariable String postId,
  ) { }

  // Query parameters
  @GetMapping('/search')
  Future<HttpResponse> search(
    @RequestParam String? query,
    @RequestParam int page = 1,
    @RequestParam int size = 10,
  ) { }

  // Request body
  @PostMapping('/create')
  Future<HttpResponse> create(@RequestBody Map<String, dynamic> data) { }

  // Request headers
  @GetMapping('/info')
  Future<HttpResponse> getInfo(
    @RequestHeader String? authorization,
    @RequestHeader('x-api-key') String? apiKey,
  ) { }

  // HTTP session
  @GetMapping('/profile')
  Future<HttpResponse> getProfile(HttpSession session) { }
}
```

### 3. Content Negotiation

**Automatic format selection**:

```dart
@RestController('/api/data')
class DataController {
  @GetMapping('/items')
  Future<HttpResponse> getItems(HttpRequest request) async {
    final items = [
      {'id': 1, 'name': 'Item 1'},
      {'id': 2, 'name': 'Item 2'},
    ];

    // Returns JSON if Accept: application/json
    // Returns XML if Accept: application/xml
    // Returns YAML if Accept: application/yaml
    return HttpResponse.ok(items);
  }
}
```

### 4. HTTP Message Converters

**Custom converters**:

```dart
@Configuration()
class ConverterConfiguration {
  @Pod()
  HttpMessageConverterRegistry createRegistry() {
    final registry = HttpMessageConverterRegistry();
    
    // JSON converter
    registry.register(JetsonHttpMessageConverter());
    
    // XML converter
    registry.register(JetsonXmlHttpMessageConverter());
    
    // Form data converter
    registry.register(FormHttpMessageConverter());
    
    return registry;
  }
}
```

### 5. Exception Handling

**Centralized error handling**:

```dart
@RestControllerAdvice()
class GlobalExceptionHandler {
  @ExceptionHandler(NotFoundException)
  HttpResponse handleNotFound(NotFoundException ex) {
    return HttpResponse.notFound(
      {'error': ex.message},
    );
  }

  @ExceptionHandler(ValidationException)
  HttpResponse handleValidation(ValidationException ex) {
    return HttpResponse.badRequest(
      {'error': 'Validation failed', 'details': ex.details},
    );
  }

  @ExceptionHandler(Exception)
  HttpResponse handleGeneric(Exception ex) {
    return HttpResponse.internalServerError(
      {'error': 'Internal server error'},
    );
  }
}
```

### 6. Multipart File Uploads

**Handle file uploads**:

```dart
@RestController('/api/files')
class FileController {
  @PostMapping('/upload')
  Future<HttpResponse> uploadFile(HttpRequest request) async {
    // Parse multipart request
    final parts = await request.getMultipartRequest().getParts();
    
    for (final part in parts) {
      if (part.isFile) {
        final filename = part.filename;
        final contentType = part.contentType;
        final bytes = await part.readBytes();
        
        // Process file
        await saveFile(filename, bytes);
      }
    }

    return HttpResponse.ok({'status': 'uploaded'});
  }
}
```

### 7. HTTP Sessions

**Session management**:

```dart
@RestController('/api')
class SessionController {
  @PostMapping('/login')
  Future<HttpResponse> login(
    @RequestBody LoginRequest req,
    HttpSession session,
  ) async {
    final user = await authenticateUser(req.email, req.password);
    if (user == null) {
      return HttpResponse.unauthorized();
    }

    session.setAttribute('user_id', user.id);
    session.setAttribute('user_email', user.email);

    return HttpResponse.ok(user);
  }

  @GetMapping('/profile')
  Future<HttpResponse> getProfile(HttpSession session) async {
    final userId = session.getAttribute('user_id');
    if (userId == null) {
      return HttpResponse.unauthorized();
    }

    final user = await getUserById(userId);
    return HttpResponse.ok(user);
  }

  @PostMapping('/logout')
  Future<HttpResponse> logout(HttpSession session) async {
    session.invalidate();
    return HttpResponse.ok({'status': 'logged out'});
  }
}
```

### 8. Template Rendering

**Render HTML with JTL**:

```dart
@RestController('/pages')
class PageController {
  final TemplateEngine _template;

  @Autowired
  PageController(this._template);

  @GetMapping('/home')
  Future<HttpResponse> homePage() async {
    final html = await _template.render(
      'pages/home.jtl',
      {'title': 'Welcome', 'user': 'John'},
    );

    return HttpResponse.ok(html)
      .header('Content-Type', 'text/html; charset=utf-8');
  }
}
```

## 🎯 Common Patterns

### Pattern 1: RESTful API Endpoint

```dart
@RestController('/api/users')
class UserController {
  final UserService _service;

  @Autowired
  UserController(this._service);

  @GetMapping('/')
  Future<HttpResponse> listUsers() async {
    final users = await _service.getAllUsers();
    return HttpResponse.ok(users);
  }

  @PostMapping('/')
  Future<HttpResponse> createUser(@RequestBody User user) async {
    final created = await _service.createUser(user);
    return HttpResponse.created(created);
  }
}
```

### Pattern 2: Error Handling with Status Codes

```dart
@GetMapping('/items/:id')
Future<HttpResponse> getItem(@PathVariable String id) async {
  final item = await _service.getItemById(id);
  
  if (item == null) {
    return HttpResponse.notFound();
  }

  return HttpResponse.ok(item);
}
```

### Pattern 3: Query Parameter Filtering

```dart
@GetMapping('/search')
Future<HttpResponse> search(
  @RequestParam String? q,
  @RequestParam int limit = 50,
) async {
  if (q == null || q.isEmpty) {
    return HttpResponse.badRequest(
      {'error': 'Query parameter required'},
    );
  }

  final results = await _service.search(q, limit: limit);
  return HttpResponse.ok(results);
}
```

## 📖 HTTP Status Codes

Common HTTP response status codes:

| Code | Method | Use Case |
|------|--------|----------|
| 200 | `ok()` | Successful GET/PUT |
| 201 | `created()` | POST created resource |
| 204 | `noContent()` | DELETE successful |
| 400 | `badRequest()` | Invalid input |
| 401 | `unauthorized()` | Missing authentication |
| 403 | `forbidden()` | Insufficient permissions |
| 404 | `notFound()` | Resource not found |
| 409 | `conflict()` | Resource conflict |
| 500 | `internalServerError()` | Server error |

## ⚠️ Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Route not matched | Wrong mapping path | Verify `@RestController` base path and method annotation |
| 400 Bad Request | Invalid request body | Ensure request body matches pod type |
| 404 Not Found | Route not registered | Check controller is in package scan paths |
| Content Negotiation fails | Missing converter | Register converter in pod factory |

## 📋 Best Practices

### ✅ DO

- Use RESTful URL patterns (`GET /users`, `POST /users`, `PUT /users/:id`)
- Return appropriate HTTP status codes
- Use `@PathVariable` for resource IDs
- Use `@RequestParam` for query/search parameters
- Use `@RequestBody` for form data
- Implement global exception handling
- Validate input before processing
- Document API endpoints with comments

### ❌ DON'T

- Use `GET` for mutations (use `POST`, `PUT`, `DELETE`)
- Return `200 OK` for errors
- Ignore content negotiation
- Forget to close multipart streams
- Share mutable state between requests
- Block the event loop in handlers
- Trust user input without validation

## 📦 Dependencies

- **`jetleaf_core`** — Core framework
- **`jetleaf_lang`** — Language utilities
- **`jetson`** — JSON serialization
- **`jtl`** — Template rendering
- **`jetleaf_logging`** — Structured logging
- **`jetleaf_env`** — Configuration

## 📄 License

This package is part of the JetLeaf Framework. See LICENSE in the root directory.

## 🔗 Related Packages

- **`jetson`** — Object mapping and serialization
- **`jtl`** — Template engine
- **`jetleaf_validation`** — Data validation
- **`jetleaf_security`** — Security utilities

## 📞 Support

For issues, questions, or contributions, visit:
- [GitHub Issues](https://github.com/jetleaf/jetleaf_web/issues)
- [Documentation](https://jetleaf.hapnium.com/docs/web)
- [Community Forum](https://forum.jetleaf.hapnium.com)

---

**Created with ❤️ by [Hapnium](https://hapnium.com)**
