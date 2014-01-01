<?php
defined('URLUPLOADER_PATH') or die('Hacking attempt!');

/**
 * add a tab on photo properties page
 */
function urluploader_tabsheet_before_select($sheets, $id)
{
  if ($id == 'photos_add')
  {
    // insert new tab at 2nd position
    $sheets = 
      array_slice($sheets, 0, 1) +
      array('url_uploader' => array(
        'caption' => '<span class="icon-link"></span>' . l10n('URL Uploader'),
        'url' => URLUPLOADER_ADMIN,
        )) +
      array_slice($sheets, 1);
  }
  
  return $sheets;
}

/*
 * try to get the mime-type of a file
 * as no method is totally reliable we can fallback to a default mime
 */
function get_mime($file, $default="application/octet-stream")
{
  if (function_exists("mime_content_type"))
  {
    $mime = mime_content_type($file);
    if (!empty($mime)) return $mime;
  }
  
  if (function_exists("finfo_file"))
  {
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $file);
    finfo_close($finfo);
    if (!empty($mime)) return $mime;
  }
  
  if (!stristr(ini_get("disable_functions"), "shell_exec"))
  {
    $file = escapeshellarg($file);
    $mime = shell_exec("file -bi " . $file);
    if (!empty($mime)) return $mime;
  }
  
  return $default;
}
