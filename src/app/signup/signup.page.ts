import { Component } from '@angular/core';
import { AuthService } from '../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-signup',
  templateUrl: './signup.page.html',
  styleUrls: ['./signup.page.scss'],
})
export class SignupPage {
  email: string = '';
  name: string = '';
  password1: string = '';
  password2: string = '';

  constructor(private Auth: AuthService, private Router: Router) {}

  signup(): void {
    if (
      this.email.trim() !== '' &&
      this.password1 === this.password2 &&
      this.password1.length >= 6 &&
      this.name.trim() != ''
    ) {
      this.Auth.signup(this.email, this.password1, this.name);
      this.email = '';
      this.name = '';
      this.password1 = '';
      this.password2 = '';
    }
  }
}
