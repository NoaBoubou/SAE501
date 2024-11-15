import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
})
export class LoginPage {
  email: string = '';
  password: string = '';

  passwordType: string = 'password';

  constructor(private Router: Router, private Auth: AuthService) {}

  onLogin() {}

  changeInputPasswordType() {
    this.passwordType = this.passwordType == 'password' ? 'text' : 'password';
  }

  login() {
    if (this.email != '' && this.password != '') {
      this.Auth.loginWithEmail(this.email, this.password);
      this.email = '';
      this.password = '';
    }
  }

  signup() {
    this.Router.navigateByUrl('signup');
  }
}
