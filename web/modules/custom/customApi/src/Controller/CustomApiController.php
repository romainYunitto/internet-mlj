<?php

namespace Drupal\customApi\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Entity\EntityStorageException;
use Drupal\Core\File\FileSystemInterface;
use Drupal\Core\Url;
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\file\Entity\File;
use Drupal\node\Entity\Node;
use Drupal\webform\Entity\Webform;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;


class CustomApiController extends ControllerBase
{

    private array $excludedFields = ['field_url'];

    /**
     * @throws EntityStorageException
     */
    public function submit(Request $request)
    {
        $webform_id = 'postuler';
        $webform = Webform::load($webform_id);
        if (!$webform) {
            return new JsonResponse(['error' => 'Webform not found'], 404);
        }

        // Récupérer les champs texte du formulaire
        $data = [
            'nom' => $request->request->get('nom'),
            'prenom' => $request->request->get('prenom'),
            'telephone' => $request->request->get('telephone'),
            'email' => $request->request->get('email'),
            'confirm_email' => $request->request->get('confirm_email'),
            'titre' => $request->request->get('titre'),
            'message' => $request->request->get('message'),
        ];

        // Champs fichiers et clefs où stocker l'URL dans $data
        $file_fields = [
            'cv' => 'cv',
            'motivation' => 'motivation',
            'autre' => 'autre',
        ];

        $directory = 'public://uploads/';
        \Drupal::service('file_system')->prepareDirectory(
            $directory,
            FileSystemInterface::CREATE_DIRECTORY | FileSystemInterface::MODIFY_PERMISSIONS
        );

        $real_path = \Drupal::service('file_system')->realpath($directory);

        if (!file_exists($real_path)) {
            mkdir($real_path, 0777, TRUE);
        }

        foreach ($file_fields as $input_name => $field_key) {
            $uploadedFile = $request->files->get($input_name);
            if ($uploadedFile) {
                $filename = $uploadedFile->getClientOriginalName();
                $filepath = $real_path . '/' . $filename;

                // Renommer si fichier existe déjà
                $filepath = \Drupal::service('file_system')->getDestinationFilename($filepath, FileSystemInterface::EXISTS_RENAME);

                // Lire contenu fichier uploadé
                $data_file = file_get_contents($uploadedFile->getPathname());

                // Sauvegarder physiquement
                file_put_contents($filepath, $data_file);

                // Obtenir URI Drupal
                $file_uri = $directory . basename($filepath);

                // Créer entité File Drupal
                $file = File::create([
                    'uri' => $file_uri,
                    'status' => "PERMANENT",
                ]);
                $file->save();

                // Récupérer URL publique
                $file_url_generator = \Drupal::service('file_url_generator');
                $absolute_url = $file_url_generator->generateAbsoluteString($file->getFileUri());

                // Stocker URL dans $data
                $data[$field_key] = $absolute_url;
            }
        }

        // Créer la soumission webform avec toutes les données
        $submission = \Drupal\webform\Entity\WebformSubmission::create([
            'webform_id' => $webform_id,
            'data' => $data,
        ]);
        $submission->save();

        return new JsonResponse([
            'message' => 'Soumission enregistrée',
            'sid' => $submission->id(),
        ]);
        /*
        if ($webform) {
            $elements = $webform->getElementsDecoded();
            dump($elements);
        }
        return new JsonResponse(['message' => 'Hello World!']);*/
    }

    /**
     * API de recherche avec extraits et filtres de date.
     */
    public function search(Request $request)
    {
        $search_term = $request->query->get('q');
        $from = $request->query->get('from');
        $to = $request->query->get('to');
        $tag_param = $request->query->get('tag');
        $type = $request->query->get('type');
        $period = $request->query->get('periode');
        $lieu = $request->query->get('lieu');
        $tags = [];

        if (!empty($tag_param)) {
            $tags = array_filter(array_map('trim', explode(',', $tag_param)));
        }
        if (!$search_term && !$type) {
            return new JsonResponse(['error' => 'Paramètre "q" ou "type" requis.'], 400);
        }

        if ($period && $type === 'agenda') {
            [$from, $to] = $this->resolveDateRangeFromPeriod($period);
        }

        $from_timestamp = $from ? strtotime($from . ' 00:00:00') : null;
        $to_timestamp = $to ? strtotime($to . ' 23:59:59') : null;

        $query = \Drupal::entityQuery('node')
            ->accessCheck(TRUE)
            ->condition('status', 1);

        if (!empty($type)) {
            $query->condition('type', $type);
        }

        if (!empty($lieu)) {
            $query->condition('field_lieu', $lieu, '=');
        }

        $tag_fields_by_type = [
            'actualite' => 'field_tag',
            'agenda' => 'field_categorie',
        ];

        if (!empty($tags) && !empty($type) && isset($tag_fields_by_type[$type])) {
            $query->condition($tag_fields_by_type[$type] . '.target_id', $tags, 'IN');
        }

        if ($type === 'agenda') {
            if ($from && $to) {
                $query->condition('field_date.value', $to, '<=');
                $query->condition('field_date_de_fin.value', $from, '>=');
            }
        } else {
            if ($from_timestamp) {
                $query->condition('created', $from_timestamp, '>=');
            }
            if ($to_timestamp) {
                $query->condition('created', $to_timestamp, '<=');
            }
        }

        $nids = $query->execute();

        if (empty($nids)) {
            return new JsonResponse(['results' => []]);
        }

        $nodes = Node::loadMultiple($nids);
        $text_fields = self::getTextFields();
        $results_by_type = [];

        foreach ($nodes as $node) {
            $excerpts = [];

            if ($search_term) {
                $found = false;

                if (stripos($node->label(), $search_term) !== false) {
                    $found = true;
                    $excerpts[] = [];
                }

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

                $paragraph_excerpts = $this->searchInParagraphs($node, $search_term);
                if (!empty($paragraph_excerpts)) {
                    $found = true;
                    $excerpts = array_merge($excerpts, $paragraph_excerpts);
                }

                if (!$found) {
                    continue;
                }
            }

            $node_type = $node->getType();

            if ($node_type === 'vie') {
                // Grouper par menu parent
                $menu_parent_label = 'Sans menu';
                if ($node->hasField('field_menu_parent') && !$node->get('field_menu_parent')->isEmpty()) {
                    $menu_link = $node->get('field_menu_parent')->entity;
                    if ($menu_link) {
                        $menu_parent_label = $menu_link->label();
                    }
                }

                if (!isset($results_by_type['vie'])) {
                    $results_by_type['vie'] = [];
                }
                if (!isset($results_by_type['vie'][$menu_parent_label])) {
                    $results_by_type['vie'][$menu_parent_label] = [];
                }

                $results_by_type['vie'][$menu_parent_label][] = [
                    'nid' => $node->id(),
                    'title' => $node->label(),
                    'image' => $this->getImageUrl($node, 'field_image'),
                    'created' => date('Y-m-d H:i:s', $node->getCreatedTime()),
                    'url' => $node->toUrl()->toString(),
                    'lieu' => '',
                    'debut' => '',
                    'fin' => '',
                    'excerpts' => $excerpts,
                ];
            } else {
                // Structure classique
                if (!isset($results_by_type[$node_type])) {
                    $results_by_type[$node_type] = [];
                }

                $tag_field_map = [
                    'actualite' => 'field_tag',
                    'agenda' => 'field_categorie',
                ];

                $tags_list = [];
                if (isset($tag_field_map[$node_type]) && $node->hasField($tag_field_map[$node_type])) {
                    $tag_field = $node->get($tag_field_map[$node_type]);
                    foreach ($tag_field as $item) {
                        if ($item->entity) {
                            $tags_list[] = $item->entity->label();
                        }
                    }
                }

                $results_by_type[$node_type][] = [
                    'nid' => $node->id(),
                    'title' => $node->label(),
                    'image' => $this->getImageUrl($node, 'field_image'),
                    'created' => date('Y-m-d H:i:s', $node->getCreatedTime()),
                    'url' => $node->toUrl()->toString(),
                    'lieu' => $node_type === "agenda" ? $node->get('field_lieu')->value : '',
                    'debut' => $node_type === "agenda" ? $node->get('field_date')->value : '',
                    'fin' => $node_type === "agenda" ? $node->get('field_date_de_fin')->value : '',
                    'field_tag_export' => $tags_list,
                    'excerpts' => $excerpts,
                ];
            }
        }

        return new JsonResponse(['results' => $results_by_type]);
    }


    /**
     * Récupère tous les champs texte des nœuds, hors champs exclus.
     */
    public
    static function getTextFields(): array
    {
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
    private
    function searchInParagraphs($entity, string $search_term)
    {
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
    private
    function extractExcerpt(string $text, string $keyword, int $context = 30)
    {
        $pos = stripos($text, $keyword);
        if ($pos === false) {
            return '';
        }

        $start = max(0, $pos - $context);
        $length = strlen($keyword) + ($context * 2);
        $excerpt = substr($text, $start, $length);

        return '...' . trim($excerpt) . '...';
    }

    public
    function getLieux(): JsonResponse
    {
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

    private
    function resolveDateRangeFromPeriod(?string $period): array
    {
        $today = new \DateTimeImmutable('today');

        switch ($period) {
            case 'weekend':
                $start = (clone $today)->modify('saturday this week');
                $end = (clone $today)->modify('sunday this week');
                break;

            case 'semaine':
                $start = (clone $today)->modify('monday this week');
                $end = (clone $today)->modify('sunday this week');
                break;

            case 'mois':
                $start = $today->modify('first day of this month');
                $end = $today->modify('last day of this month');
                break;

            case 'mois_prochain':
                $start = $today->modify('first day of next month');
                $end = $today->modify('last day of next month');
                break;

            default:
                return [null, null];
        }

        return [
            $start->format('Y-m-d'),
            $end->format('Y-m-d'),
        ];
    }

    private
    function getImageUrl($node, string $field_name): ?string
    {
        if ($node->hasField($field_name) && !$node->get($field_name)->isEmpty()) {
            $file = $node->get($field_name)->entity;
            if ($file) {
                $uri = $file->getFileUri();
                $file_url_generator = \Drupal::service('file_url_generator');
                return $file_url_generator->generateAbsoluteString($uri);
            }
        }
        return null;
    }

    public function getAgendaPeriode(): JsonResponse
    {
        $periodes = [
            "weekend" => " Ce week-end",
            "semaine" => " Cette semaine",
            "mois" => " Ce mois ci",
            "mois_prochain" => " Le mois prochain"
        ];

        return new JsonResponse(['results' => $periodes]);

    }
}
