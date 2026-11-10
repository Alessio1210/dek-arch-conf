; extends
; Spring Boot and JPA annotations get a distinct IntelliJ-style accent.  The
; built-in Java query still handles every other annotation normally.
[
  (annotation
    name: (identifier) @attribute.spring)
  (marker_annotation
    name: (identifier) @attribute.spring)
]
(#any-of? @attribute.spring
  "SpringBootApplication"
  "SpringBootTest"
  "RestController"
  "Controller"
  "Service"
  "Repository"
  "Component"
  "Configuration"
  "Bean"
  "Autowired"
  "Value"
  "RequestMapping"
  "GetMapping"
  "PostMapping"
  "PutMapping"
  "DeleteMapping"
  "PatchMapping"
  "PathVariable"
  "RequestParam"
  "RequestBody"
  "ResponseBody"
  "Entity"
  "Table"
  "Id"
  "GeneratedValue"
  "Column"
  "OneToOne"
  "OneToMany"
  "ManyToOne"
  "ManyToMany"
  "Transactional")
