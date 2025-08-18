<?php

namespace Drupal\customApi\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Drupal\Core\Controller\ControllerBase;
use Drupal\node\Entity\Node;
use Drupal\field\Entity\FieldStorageConfig;

class CustomApiController extends ControllerBase
{

  private array $excludedFields = ['field_url'];

  /**
   * API de recherche avec extraits et filtres de date.
   */
  public function search(Request $request) {
    $search_term = $request->query->get('q');
    $from = $request->query->get('from');
    $to = $request->query->get('to');

    if (!$search_term) {
      return new JsonResponse(['error' => 'Paramètre "q" requis.'], 400);
    }

    // Dates
    $from_timestamp = $from ? strtotime($from . ' 00:00:00') : null;
    $to_timestamp = $to ? strtotime($to . ' 23:59:59') : null;

    // Requête sur les nœuds
    $query = \Drupal::entityQuery('node')
      ->accessCheck(TRUE)
      ->condition('status', 1);

    if ($from_timestamp) {
      $query->condition('created', $from_timestamp, '>=');
    }

    if ($to_timestamp) {
      $query->condition('created', $to_timestamp, '<=');
    }

    $nids = $query->execute();

    if (empty($nids)) {
      return new JsonResponse(['results' => []]);
    }

    $nodes = Node::loadMultiple($nids);
    $text_fields = self::getTextFields();
    $results_by_type = [];

    foreach ($nodes as $node) {
      $found = false;
      $excerpts = [];

      // Recherche dans le titre
      if (stripos($node->label(), $search_term) !== false) {
        $found = true;
        $excerpts[] = [];
      }

      // Recherche dans les champs texte
      foreach ($text_fields as $field_name) {
        if (in_array($field_name, $this->excludedFields)) {
          continue;
        }

        if ($node->hasField($field_name) && !$node->get($field_name)->isEmpty()) {
          $value = $node->get($field_name)->value ?? '';
          if (stripos($value, $search_term) !== false) {
            $found = true;
            $excerpts[] = [
              'excerpt' => $this->extractExcerpt($value, $search_term),
            ];
          }
        }
      }

      // Recherche dans les paragraphes
      $paragraph_excerpts = $this->searchInParagraphs($node, $search_term);
      if (!empty($paragraph_excerpts)) {
        $found = true;
        $excerpts = array_merge($excerpts, $paragraph_excerpts);
      }

      // Ajout au groupe par type si trouvé
      if ($found) {
        $type = $node->getType();
        if (!isset($results_by_type[$type])) {
          $results_by_type[$type] = [];
        }

        $results_by_type[$type][] = [
          'nid' => $node->id(),
          'title' => $node->label(),
          'created' => date('Y-m-d H:i:s', $node->getCreatedTime()),
          'url' => $node->toUrl()->toString(),
          'excerpts' => $excerpts,
        ];
      }
    }
    return new JsonResponse(['results' => $results_by_type]);
  }

  /**
   * Récupère tous les champs texte des nœuds, hors champs exclus.
   */
  public static function getTextFields(): array {
    $fields = FieldStorageConfig::loadMultiple();
    $text_fields = [];

    foreach ($fields as $field) {
      if ($field->getTargetEntityTypeId() === 'node') {
        $type = $field->getType();
        if (in_array($type, ['string', 'text', 'text_long', 'text_with_summary'])) {
          $text_fields[] = $field->getName();
        }
      }
    }

    return $text_fields;
  }

  /**
   * Recherche dans les paragraphes, en excluant les champs ignorés.
   */
  private function searchInParagraphs($entity, string $search_term) {
    $results = [];

    foreach ($entity->getFields() as $field) {
      if (
        $field->getFieldDefinition()->getType() === 'entity_reference_revisions' &&
        $field->getFieldDefinition()->getSetting('target_type') === 'paragraph'
      ) {
        foreach ($field->referencedEntities() as $paragraph) {
          foreach ($paragraph->getFields() as $pfield) {
            $field_type = $pfield->getFieldDefinition()->getType();
            $field_name = $pfield->getName();

            if (in_array($field_name, $this->excludedFields)) {
              continue;
            }

            // Champs texte
            if (in_array($field_type, ['string', 'text', 'text_long', 'text_with_summary'])) {
              $val = isset($pfield->value) ? $pfield->value : '';
              if (stripos($val, $search_term) !== false) {
                $results[] = [
                  'field' => $field_name,
                  'excerpt' => $this->extractExcerpt($val, $search_term),
                ];
              }
            }

            // Sous-paragraphes
            if (
              $field_type === 'entity_reference_revisions' &&
              $pfield->getFieldDefinition()->getSetting('target_type') === 'paragraph'
            ) {
              foreach ($pfield->referencedEntities() as $sub_paragraph) {
                $sub_results = $this->searchInParagraphs($sub_paragraph, $search_term);
                if (!empty($sub_results)) {
                  $results = array_merge($results, $sub_results);
                }
              }
            }
          }
        }
      }
    }

    return $results;
  }

  /**
   * Génère un extrait contextuel autour du mot-clé.
   */
  private function extractExcerpt(string $text, string $keyword, int $context = 30) {
    $pos = stripos($text, $keyword);
    if ($pos === false) {
      return '';
    }

    $start = max(0, $pos - $context);
    $length = strlen($keyword) + ($context * 2);
    $excerpt = substr($text, $start, $length);

    return '...' . trim($excerpt) . '...';
  }

  public function getLieux(): JsonResponse {
    $query = \Drupal::entityQuery('node')
      ->accessCheck(TRUE)
      ->condition('status', 1)
      ->exists('field_lieu');

    $nids = $query->execute();
    if (empty($nids)) {
      return new JsonResponse(['values' => []]);
    }

    $nodes = \Drupal\node\Entity\Node::loadMultiple($nids);
    $values = [];

    foreach ($nodes as $node) {
      if ($node->hasField('field_lieu') && !$node->get('field_lieu')->isEmpty()) {
        $raw_value = $node->get('field_lieu')->value;
        if ($raw_value) {
          $values[] = trim($raw_value);
        }
      }
    }

    $unique = array_values(array_unique($values));
    sort($unique);

    return new JsonResponse(['values' => $unique]);
  }

}
