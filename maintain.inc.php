<?php
defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

function plugin_uninstall() 
{
  pwg_query('DELETE FROM `'. CONFIG_TABLE .'` WHERE param = "url_uploader_mode" LIMIT 1;');
}

?>