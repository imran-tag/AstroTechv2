import { Component, OnInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common'; 
import { FormsModule } from '@angular/forms'; 
import { AffairesService } from '../../_services/affaires/affaires.service';

declare var bootstrap: any;

@Component({
  selector: 'app-choix-intervention',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './choix-intervention.component.html'
})
export class ChoixInterventionComponent implements OnInit {
  modalInstance: any;
  affaires: any[] = [];
  searchTerm = '';
  
  // Variables de pagination
  page = 1;
  limit = 4;
  totalItems = 0;
  totalPages = 1;

  typeCreation: string | null = null;

  constructor(private router: Router, private affaireService: AffairesService) {}

  ngOnInit(): void {
    // Initialisation si nécessaire au chargement du composant
  }

  /**
   * Charge les données depuis le service avec pagination et recherche
   */
  loadAffaires() {
    this.affaireService.getAllPaginated(this.page, this.limit, this.searchTerm).subscribe({
      next: (res: any) => {
        this.affaires = res.data;
        this.totalItems = res.total || 0;
        this.totalPages = Math.ceil(this.totalItems / this.limit);
      },
      error: (err) => console.error('Erreur chargement:', err)
    });
  }

  /**
   * Gère la recherche : réinitialise à la page 1 pour éviter les erreurs d'index
   */
  onSearch() {
    this.page = 1;
    this.loadAffaires();
  }

  /**
   * Change la page actuelle et recharge les données
   * @param newPage Le numéro de la page cible
   */
  changePage(newPage: number) {
    if (newPage >= 1 && newPage <= this.totalPages) {
      this.page = newPage;
      this.loadAffaires();
    }
  }

  openModal() {
    this.page = 1; // On repart de la première page à l'ouverture
    this.loadAffaires();
    const modalElement = document.getElementById('affaireModal');
    if (modalElement) {
      this.modalInstance = new bootstrap.Modal(modalElement);
      this.modalInstance.show();
    }
  }

  annuler() {
    this.router.navigate(['/interventions/list']);
  }

  selectOption(type: string) {
    this.typeCreation = type;
    if (type === 'rapide') {
      this.router.navigate(['/interventions/edit']);
    } else {
      this.openModal();
    }
  }

  goToIntervention(affaire: any) {
    if (this.modalInstance) {
      this.modalInstance.hide();
    }
    this.router.navigate(['/interventions/edit'], { 
      queryParams: { affaireId: affaire.affaireId } 
    });
  }

  // --- Helpers UI ---

  getInitials(name: string): string {
    if (!name) return '??';
    const parts = name.trim().split(' ');
    return parts.length >= 2 
      ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase() 
      : name.substring(0, 2).toUpperCase();
  }

  getAvatarStyle(text: string): any {
    if (!text) return { 'background-color': '#ccc' };
    let hash = 0;
    for (let i = 0; i < text.length; i++) {
      hash = text.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash % 360);
    return { 
      'background-color': `hsl(${h}, 60%, 50%)`, 
      'color': 'white', 
      'width': '35px', 
      'height': '35px', 
      'border-radius': '50%',
      'display': 'inline-flex', 
      'align-items': 'center', 
      'justify-content': 'center',
      'font-size': '12px', 
      'font-weight': 'bold', 
      'border': '2px solid white',
      'box-shadow': '0 2px 4px rgba(0,0,0,0.1)', 
      'margin-left': '-10px'
    };
  }
}