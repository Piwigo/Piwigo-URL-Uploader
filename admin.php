<?php
defined('URLUPLOADER_PATH') or die('Hacking attempt!');
 
global $template, $page, $conf;

load_language('plugin.lang', URLUPLOADER_PATH);

// +-----------------------------------------------------------------------+
// | URL Uploader tab                                                      |
// +-----------------------------------------------------------------------+
define('PHOTOS_ADD_BASE_URL', get_root_url().'admin.php?page=photos_add');

include_once(PHPWG_ROOT_PATH.'admin/include/functions.php');
include_once(PHPWG_ROOT_PATH.'admin/include/tabsheet.class.php');
include_once(PHPWG_ROOT_PATH.'admin/include/functions_upload.inc.php');

$tabsheet = new tabsheet();
$tabsheet->set_id('photos_add');
$tabsheet->select('url_uploader');
$tabsheet->assign();

$page['active_menu'] = get_active_menu('photo');


// +-----------------------------------------------------------------------+
// |                             prepare form                              |
// +-----------------------------------------------------------------------+
include(PHPWG_ROOT_PATH.'admin/include/photos_add_direct_prepare.inc.php');

$template->set_filename('urluploader_content', realpath(URLUPLOADER_PATH . 'template/photos_add.tpl'));

// template vars
$template->assign(array(
  'URLUPLOADER_PATH' => get_root_url() . URLUPLOADER_PATH,
  'URLUPLOADER_ADMIN' => URLUPLOADER_ADMIN,
  ));
  
// send page content
$template->assign_var_from_handle('ADMIN_CONTENT', 'urluploader_content');
