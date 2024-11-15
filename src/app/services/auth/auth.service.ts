import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
} from 'firebase/auth';
import { auth } from 'src/environments/environment';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  dbPath = 'users';
  constructor(private Router: Router) {}

  loginWithEmail(email: string, password: string) {
    signInWithEmailAndPassword(auth, email, password)
      .then((userCredential) => {
        const user = userCredential.user;
        this.Router.navigateByUrl('home');
      })
      .catch((error) => {
        const errorCode = error.code;
        const errorMessage = error.message;
      });
  }

  signup(email: string, password: string, name: string) {
    createUserWithEmailAndPassword(auth, email, password)
      .then((result) => {
        updateProfile(result.user, {
          displayName: name,
        });
        const user = { ...result.user, displayName: name };
        this.Router.navigateByUrl('home');
      })
      .catch((error) => {
        const errorCode = error.code;
        const errorMessage = error.message;
      });
  }

  signout() {
    signOut(auth).catch((error) => {});
  }
}
