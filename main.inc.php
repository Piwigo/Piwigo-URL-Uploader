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


// +-----------------------------------------------------------------------+
// | Define plugin constants                                               |
// +-----------------------------------------------------------------------+
defined('URLUPLOADER_ID') or define('URLUPLOADER_ID', basename(dirname(__FILE__)));
define('URLUPLOADER_PATH' ,   PHPWG_PLUGINS_PATH . URLUPLOADER_ID . '/');
define('URLUPLOADER_ADMIN',   get_root_url() . 'admin.php?page=plugin-' . URLUPLOADER_ID);


// +-----------------------------------------------------------------------+
// | Add event handlers                                                    |
// +-----------------------------------------------------------------------+
if (defined('IN_ADMIN'))
{
  // new tab on photo page
  add_event_handler('tabsheet_before_select', 'urluploader_tabsheet_before_select', EVENT_HANDLER_PRIORITY_NEUTRAL, 2);
}

// add API function
add_event_handler('ws_add_methods', 'urluploader_ws_add_methods');

include_once(URLUPLOADER_PATH . 'include/functions.inc.php');
include_once(URLUPLOADER_PATH . 'include/ws_functions.inc.php');

?>