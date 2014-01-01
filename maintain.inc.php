<?php
defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

function plugin_uninstall() 
{
  conf_delete_param('url_uploader_mode');
}
