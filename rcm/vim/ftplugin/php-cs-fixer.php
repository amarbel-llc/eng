<?php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = Finder::create()
    // Specify the directories and files to scan
    ->in(__DIR__)
    ->exclude('var') // Exclude specific directories
;

$config = new Config();
return $config
    ->setRules([
        '@PSR12' => true,
        /* '@PhpCsFixer' => true, */
        'array_syntax' => ['syntax' => 'short'],
        'array_indentation' => true,
        'binary_operator_spaces' => ['default' => 'single_space'],
        'no_unused_imports' => true, // Enforce no unused imports
        'method_chaining_indentation' => true,
    ])
    ->setFinder($finder)
    ->setRiskyAllowed(true); // Allows "risky" rules that might change code logic
