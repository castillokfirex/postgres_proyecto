# Modelo Físico Entidad-Relación (SG-SST)

Este diagrama se genera dinámicamente con código utilizando **Mermaid**. Es ideal para documentar tu proyecto ya que nunca pierde calidad, no pesa nada y es 100% texto puro.

Puedes previsualizarlo en VS Code presionando `Ctrl + Shift + V` (o instalando la extensión **Mermaid Preview** si tu VS Code no la renderiza nativamente), o bien subiendo este archivo a GitHub donde se dibujará mágicamente.

```mermaid
erDiagram
    COUNTRIES ||--o{ DEPARTMENTS : "contiene"
    DEPARTMENTS ||--o{ MUNICIPALITIES : "contiene"
    
    TENANT_SIZES ||--o{ TENANTS : "clasifica"
    MUNICIPALITIES ||--o{ TENANTS : "ubica"
    
    TENANTS ||--o{ PERSONS : "emplea"
    TENANTS ||--o{ POSITIONS : "define_cargo"
    POSITIONS ||--o{ PERSONS : "ocupa"
    
    TYPE_SYSTEM_SST ||--o{ MODULES : "se_divide_en"
    TYPE_SYSTEM_SST ||--o{ TENANTSYSTEMS : "habilita_en"
    TYPE_SYSTEM_SST ||--o{ TEMPLATES : "usa"
    
    MODULES ||--o{ FORMATS_SST : "tiene"
    MODULES ||--o{ TENANT_MODULES : "asigna_a"
    MODULES ||--o{ TEMPLATES : "categoriza"
    
    STAGES_PHVA ||--o{ TEMPLATES : "pertenece_a"
    
    TENANTS ||--o{ TENANTSYSTEMS : "tiene"
    TENANTS ||--o{ TENANT_MODULES : "tiene"
    TENANTS ||--o{ TENANT_TEMPLATES : "gestiona"
    TENANTS ||--o{ EVALUATIONS : "recibe"
    TENANTS ||--o{ EDITING_LOCKS : "bloquea"
    
    TEMPLATES ||--o{ TENANT_TEMPLATES : "instancia"
    TEMPLATES ||--o{ EVALUATIONS : "evalua"
    
    FORMATS_SST ||--o{ TENANT_TEMPLATES : "llena"
    PERSONS ||--o{ EDITING_LOCKS : "bloqueado_por"

    %% Notas de tablas sueltas (Auditoría)
    AUDIT_TENANTS {
        int id
        int tenant_id
    }
    AUDIT_TEMPLATES {
        int id
        int template_id
    }
```
