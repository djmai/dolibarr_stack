# Directorio de DOLIBARR ERP & CRM para los documentos

Este directorio está dedicado a almacenar todos los documentos que genera dolibarr.

Nota: En sistemas Linux o MAC, es mejor almacenar el directorio en un lugar fuera de la raíz de htdocs o public

¡¡¡ADVERTENCIA!!!
Compruebe también que el directorio /documents esté activo añadiendo al archivo `conf/conf.php` de dolibarr las dos líneas siguientes, de modo que dolibarr también escanee el directorio /documents para encontrar documentos:

```php
$dolibarr_main_data_root="/path_to_dolibarr/documents";
```