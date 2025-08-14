<?php
namespace Drupal\typo3_migration\Plugin\migrate\process;
use Drupal\migrate\ProcessPluginBase;
use Drupal\migrate\MigrateExecutableInterface;
use Drupal\migrate\Row;

/**
 * @MigrateProcessPlugin(id = "html_clean")
 */
class HtmlClean extends ProcessPluginBase {
  public function transform($value, MigrateExecutableInterface $migrate_executable, Row $row, $destination_property) {
    $value = preg_replace('/ style="[^"]*"/i', '', $value); // Supprime les styles en ligne
    // Ajouter ici d'autres logiques de nettoyage si nécessaire
    return $value;
  }
}
