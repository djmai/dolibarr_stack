# Directorio personalizado de DOLIBARR ERP & CRM para módulos externos

Este directorio está dedicado a almacenar módulos externos.
Para usarlo, simplemente copie aquí el directorio del módulo en este directorio.

Nota: En sistemas Linux o MAC, es mejor descomprimir/almacenar el directorio del módulo externo en
un lugar diferente a este directorio y simplemente agregar un enlace simbólico aquí al directorio htdocs
del módulo.

Por ejemplo, en el sistema operativo Linux: Obtenga el módulo con el comando

`mkdir ~/git; cd ~/git`

`git clone https://git.framasoft.org/p/newmodule/newmodule.git`

Luego cree el enlace simbólico

`ln -fs ~/git/newmodule/htdocs /path_to_dolibarr/htdocs/custom/newmodule`

¡¡¡ADVERTENCIA!!!
Compruebe también que el directorio /custom esté activo añadiendo al archivo `conf/conf.php` de dolibarr las dos líneas siguientes, de modo que dolibarr también escanee el directorio /custom para encontrar módulos externos:

```php
$dolibarr_main_url_root_alt='/custom';
$dolibarr_main_document_root_alt='/path_to_dolibarr/htdocs/custom/';
```