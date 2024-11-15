import { CanActivateFn } from '@angular/router';
import { Router } from '@angular/router';
import { inject } from '@angular/core';
import { auth } from '../../environments/environment';

export const authGuard: CanActivateFn = (route, state) => {
  let router = inject(Router);
  if (auth.currentUser !== null) {
    return true;
  } else {
    router.navigateByUrl('login');
    return false;
  }
};
