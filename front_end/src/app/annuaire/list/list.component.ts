import { Component, ViewChild } from '@angular/core';
import { SharedModule } from '../../_globale/shared/shared.module';
import { ModalSaveComponent } from '../modal-save/modal-save.component';
import { ClientsService } from '../../_services/clients/clients.service';
import { Router, RouterModule } from '@angular/router';

// Définition des interfaces pour le typage strict
interface Email { email: string; }
interface Tel { tel: string; }
interface Contact {
  nom_complet: string;
  poste: string;
  listEmails: Email[];
  listTels: Tel[];
}
export interface Client {
  id: number;
  numero: string;
  nom_client: string;
  type_client: string;
  adresse?: {           // Le '?' est crucial ici
    adresse: string;
    code_postal: string;
    ville: string;
    etage?: string;
    porte_entree?: string;
    appartement_local?: string;
  };
  contacts?: any[];     // Le '?' évite l'erreur undefined sur le .length
}

@Component({
  selector: 'app-list',
  standalone: true, // Si vous utilisez Angular 14+ standalone
  imports: [SharedModule, ModalSaveComponent, RouterModule],
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.css']
})
export class ListComponent {
  @ViewChild('modalSave') modalSave!: ModalSaveComponent;

  clients: Client[] = [];
  currentPage: number = 1;
  pageSize: number = 20;
  totalItems: number = 0;
  totalPages: number = 1;
  searchTerm: string = '';

  constructor(
    private clientsService: ClientsService,
    private router: Router
  ) {
    this.loadClients();
  }

  loadClients(page: number = 1, search: string = '') {
    this.clientsService.getAllClientsWithContactsPaginated(page, this.pageSize, search).subscribe({
      next: (res: any) => {
        this.clients = res.data || [];
        this.totalItems = res.total || 0;
        this.totalPages = Math.ceil(this.totalItems / this.pageSize);
        this.currentPage = page;
      },
      error: (err) => console.error('Erreur chargement clients', err)
    });
  }

  searchClients() {
    this.loadClients(1, this.searchTerm);
  }

  changePage(page: number) {
    if (page >= 1 && page <= this.totalPages) {
      this.loadClients(page, this.searchTerm);
    }
  }

  deleteClient(id: number) {
    if (confirm('Voulez-vous vraiment supprimer ce client ?')) {
      this.clientsService.delete(id).subscribe({
        next: () => {
          this.loadClients(this.currentPage, this.searchTerm);
          alert('Client supprimé avec succès !');
        },
        error: (err) => alert('Erreur lors de la suppression.')
      });
    }
  }

  editClient(client: Client) {
    if (this.modalSave) {
      this.modalSave.editClient(client);
    }
  }

  viewDetails(client: Client) {
    this.router.navigate(['/clients/details', client.id], { 
      queryParams: { type: client.type_client } 
    });
  }
}