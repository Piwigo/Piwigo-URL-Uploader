<?php 
/*
Plugin Name: URL Uploader
Version: auto
Description: Add photos from remote URL (see Admin->Photos->Add)
Plugin URI: auto
Author: Mistic
Author URI: http://www.strangeplanet.fr
*/

defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

if (basename(dirname(__FILE__)) != 'url_uploader')
{
  add_event_handler('init', 'urluploader_error');
  function urluploader_error()
  {
    global $page;
    $page['errors'][] = 'URL Uploader folder name is incorrect, uninstall the plugin and rename it to "url_uploader"';
  }
  return;
}


define('URLUPLOADER_PATH' , PHPWG_PLUGINS_PATH . 'url_uploader/');
define('URLUPLOADER_ADMIN', get_root_url() . 'admin.php?page=plugin-url_uploader');


if (defined('IN_ADMIN'))
{
  add_event_handler('tabsheet_before_select', 'urluploader_tabsheet_before_select', EVENT_HANDLER_PRIORITY_NEUTRAL, 2);
}

add_event_handler('ws_add_methods', 'urluploader_ws_add_methods');


include_once(URLUPLOADER_PATH . 'include/functions.inc.php');
include_once(URLUPLOADER_PATH . 'include/ws_functions.inc.php');
