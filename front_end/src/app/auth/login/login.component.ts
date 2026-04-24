import { Component } from '@angular/core';
import { AuthService } from '../../_services/auth.service';
import { Router, RouterLink } from '@angular/router';
import { SharedModule } from '../../_globale/shared/shared.module';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [SharedModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {

  model = { email: '', password: '' };
  error?: string;
  showPassword = false;
  loading = false; // spinner pendant la connexion

  constructor(private auth: AuthService, private router: Router) {}

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

  onSubmit() {
    this.error = undefined;
    this.loading = true;

    this.auth.login(this.model).subscribe({
      next: (response: any) => {
        this.loading = false;

        // ✅ Stockage du token JWT dans localStorage
        if (response.token) {
          localStorage.setItem('token', response.token);
        }

        // ✅ Stockage des informations utilisateur si disponibles
        if (response.user) {
          localStorage.setItem('user', JSON.stringify(response.user));
        }

        // Redirection après connexion
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.loading = false;

        // Gestion des erreurs
        if (err.status === 401) {
          this.error = 'Adresse email ou mot de passe incorrect.';
        } else if (err.status === 0) {
          this.error = 'Serveur injoignable. Vérifiez votre connexion.';
        } else {
          this.error = err.error?.message || 'Une erreur est survenue.';
        }
      }
    });
  }
}
