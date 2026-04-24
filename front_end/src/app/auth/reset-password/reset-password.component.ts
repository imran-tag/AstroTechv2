import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { lastValueFrom } from 'rxjs';
import { AuthService } from '../../_services/auth.service';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './reset-password.component.html',
  styleUrls: ['./reset-password.component.css']
})
export class ResetPasswordComponent implements OnInit {
  token: string = '';
  newPassword: string = '';
  confirmPassword: string = '';

  loading: boolean = false;
  message: string | null = null;
  error: string | null = null;
  showPassword: boolean = false;

  constructor(
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router
  ) { }

  ngOnInit() {
    // Récupère le token dans l'URL (ex: /reset-password/abcde123)
    this.token = this.route.snapshot.paramMap.get('token') || '';
    if (!this.token) {
      this.error = "Jeton de réinitialisation manquant.";
    }
  }

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

  async onResetPassword() {
    // 1. Validation locale
    if (!this.newPassword || this.newPassword.length < 6) {
      this.error = "Le mot de passe doit contenir au moins 6 caractères.";
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.error = "Les mots de passe ne correspondent pas.";
      return;
    }

    this.loading = true;
    this.error = null;
    this.message = null;

    try {
      // 2. Appel au service 
      // On passe le token et le mot de passe séparément pour correspondre à la signature du service
      await lastValueFrom(this.authService.resetPassword(this.token, this.newPassword));

      this.message = "Mot de passe réinitialisé avec succès ! Redirection...";

      // 3. Redirection après succès
      setTimeout(() => {
        this.router.navigate(['/login']);
      }, 3000);

    } catch (err: any) {
      console.error("Erreur réinitialisation:", err);
      // On récupère le message d'erreur du backend s'il existe
      this.error = err.error?.message || "Une erreur est survenue ou le lien a expiré.";
    } finally {
      this.loading = false;
    }
  }

}