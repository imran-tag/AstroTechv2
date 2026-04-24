import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { lastValueFrom } from 'rxjs';
import { AuthService } from '../../_services/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.css']
})
export class ForgotPasswordComponent {
  email: string = '';
  loading: boolean = false;
  message: string | null = null;
  error: string | null = null;

  constructor(private authService: AuthService) {}

  async onResetRequest() {
    if (!this.email) return;
    
    this.loading = true;
    this.error = null;
    this.message = null;

    try {
      await lastValueFrom(this.authService.forgotPassword(this.email));
      this.message = "Si cet email existe, un lien a été envoyé.";
    } catch (err: any) {
      this.error = "Une erreur est survenue. Veuillez réessayer.";
    } finally {
      this.loading = false;
    }
  }
}