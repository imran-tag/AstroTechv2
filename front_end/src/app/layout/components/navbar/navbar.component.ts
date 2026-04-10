import { Component, ElementRef, HostListener } from '@angular/core';
import { AuthService } from '../../../_services/auth.service';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css'
})
export class NavbarComponent {
  user$: Observable<any>;
  isDropdownOpen = false;

  constructor(
    private auth: AuthService, 
    private router: Router,
    private eRef: ElementRef // Permet de détecter si on clique à l'intérieur du composant
  ) {
    this.user$ = this.auth.currentUser$;
  }

  /**
   * Alterne l'affichage du menu
   */
  toggleDropdown(event: Event) {
    event.preventDefault();
    this.isDropdownOpen = !this.isDropdownOpen;
  }

  /**
   * Ferme le menu
   */
  closeDropdown() {
    this.isDropdownOpen = false;
  }

  /**
   * Ferme le menu si l'utilisateur clique n'importe où en dehors de la navbar
   */
  @HostListener('document:click', ['$event'])
  clickout(event: Event) {
    if (!this.eRef.nativeElement.contains(event.target)) {
      this.isDropdownOpen = false;
    }
  }

  /**
   * Génère les initiales à partir du nom complet
   * Exemple: "Jean Dupont" -> "JD"
   */
  getInitials(name: any): string {
    if (!name || typeof name !== 'string') return 'U';
    
    const parts = name.trim().split(' ');
    if (parts.length > 1) {
      // Prend la première lettre du premier et du dernier mot
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.charAt(0).toUpperCase();
  }

  /**
   * Déconnexion et redirection
   */
  logout() {
    this.auth.logout();
    this.isDropdownOpen = false;
    this.router.navigate(['/login']);
  }
}