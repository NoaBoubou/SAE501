import { Component } from '@angular/core';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
})
export class LoginPage {
  email: string = '';
  password: string = '';

  passwordType: string = 'password';

  constructor() {}

  onLogin() {}

  changeInputPasswordType() {
    this.passwordType = this.passwordType == 'password' ? 'text' : 'password';
  }
}
