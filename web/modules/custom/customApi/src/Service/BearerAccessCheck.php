<?php

namespace Drupal\customApi\Service;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Routing\Access\AccessInterface;
use Drupal\Core\Session\AccountInterface;
use Symfony\Component\HttpFoundation\RequestStack;

class BearerAccessCheck implements AccessInterface
{

  protected $requestStack;
  protected $validToken;

  public function __construct(RequestStack $request_stack)
  {
    $this->requestStack = $request_stack;

  }

  public function access(AccountInterface $account)
  {
    $request = $this->requestStack->getCurrentRequest();
    $authHeader = $request->headers->get('Authorization');
    $path = $request->getPathInfo();
    $protectedPaths = [
      '/jsonapi/custom/search',
      '/jsonapi/custom/lieux',
      '/jsonapi/custom/periode',
    ];
    if (!in_array($path, $protectedPaths)) {
      return AccessResult::allowed();
    }
    if ($authHeader && preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
      return AccessResult::allowed();
    }
    return AccessResult::forbidden('Token invalide ou absent.');
  }
}

