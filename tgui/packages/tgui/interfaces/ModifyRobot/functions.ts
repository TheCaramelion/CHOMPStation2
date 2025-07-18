import { flow } from 'tgui-core/fp';
import { createSearch } from 'tgui-core/string';

import type { Module } from './types';

type SearchObject = string | { name: string };

export function prepareSearch<T extends SearchObject>(
  objects: T[],
  searchText: string = '',
): T[] {
  const testSearch = createSearch(searchText, (object: T): string => {
    if (typeof object === 'string') {
      return object;
    } else {
      return object.name;
    }
  });
  return flow([
    (objects: T[]) => {
      // Optional search term
      if (!searchText) {
        return objects as any;
      } else {
        return objects.filter(testSearch) as any;
      }
    },
  ])(objects);
}

export function getModuleIcon(modules: Module[], name: string) {
  if (modules) {
    const module = modules.filter((module) => module.name === name);
    if (module.length > 0) {
      return module[0].icon;
    }
  }
  return '';
}
