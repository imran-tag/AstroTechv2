import { Component, OnInit } from '@angular/core';
import { RouterLink, RouterModule } from '@angular/router';
import { AuthService } from '../../../_services/auth.service';
import { CommonModule } from '@angular/common'; // Import indispensable pour le HTML

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.css'
})
export class SidebarComponent implements OnInit {
  currentUser: any;
  initials: string = '';

  constructor(public auth: AuthService) { }

  ngOnInit(): void {
    this.getCurrentUser();
  }

  /**
   * Récupère les données de l'utilisateur et génère les initiales
   */
  getCurrentUser() {
    this.auth.fetchMe().subscribe({
      next: (result) => {
        this.currentUser = result.user;
        console.log("***",result.user);
        
        if (this.currentUser && this.currentUser.full_name) {
          this.initials = this.generateInitials(this.currentUser.full_name);
        }
      },
      error: (err) => {
        console.error('Erreur lors de la récupération de l\'utilisateur', err);
      }
    });
  }

  /**
   * Logique de génération des initiales
   */
  private generateInitials(name: string): string {
    const parts = name.trim().split(' ');
    if (parts.length > 1) {
      // Retourne la première lettre du premier et du dernier mot (ex: "John Doe" -> "JD")
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.charAt(0).toUpperCase();
  }
}