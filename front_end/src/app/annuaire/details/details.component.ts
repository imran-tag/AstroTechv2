import { Component, ViewChild, OnInit } from '@angular/core';
import { ActivatedRoute, Router, RouterModule, ParamMap } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { combineLatest } from 'rxjs';

// Services
import { SharedModule } from '../../_globale/shared/shared.module';
import { ModalSaveComponent } from '../modal-save/modal-save.component';
import { ClientsService } from '../../_services/clients/clients.service';
import { SecteurService } from '../../_services/clients/secteur.service';
import { HabitationService } from '../../_services/clients/habitation.service';
import { OrganisationsService } from '../../_services/clients/organisations.service';
import { ParticuliersService } from '../../_services/clients/particuliers.service';
import { AgencesService } from '../../_services/clients/agences.service';
import { NavigationService, NavStep } from '../../_services/navigation.service';

declare var bootstrap: any;

@Component({
  selector: 'app-details',
  standalone: true,
  imports: [CommonModule, SharedModule, ModalSaveComponent, RouterModule, FormsModule],
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {

  @ViewChild('modalSave') modalSave!: ModalSaveComponent;

  // Données principales
  id!: number;
  client: any;
  clients: any[] = [];
  iHistory: any[] = [];
  affaires: any[] = [];
  selectedIntervention: any;

  // Pagination Enfants
  clientsPage = 1;
  clientsLimit = 4;
  clientsTotal = 0;

  // Pagination Interventions
  historyPage = 1;
  historyLimit = 10;
  historyTotal = 0;

  // Pagination Affaires
  affairesPage = 1;
  affairesLimit = 10;
  affairesTotal = 0;
  affairesSearch = '';

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private clientsService: ClientsService,
    private secteurService: SecteurService,
    private habitationService: HabitationService,
    private organisationsService: OrganisationsService,
    private particuliersService: ParticuliersService,
    private agencesService: AgencesService,
    public navService: NavigationService
  ) { }

  ngOnInit(): void {
    // Écoute les changements d'ID et de Type simultanément (important pour la navigation imbriquée)
    combineLatest([
      this.route.paramMap,
      this.route.queryParamMap
    ]).subscribe(([params, queryParams]) => {
      const newId = Number(params.get('id'));
      const newType = queryParams.get('type');

      if (newId && newType) {
        this.id = newId;
        this.resetPagination();
        this.loadClient(this.id, newType);
      }
    });
  }

  // --- CHARGEMENT DES DONNÉES ---

  loadClient(id: number, type: string) {
    const handleSuccess = (res: any) => {
      this.client = res.data || res;
      const label = this.client.nom_client || this.client.nom || 'Détails';

      // Mise à jour du Fil d'Ariane
      this.navService.pushStep(id, label, type);

      // Chargement des listes liées
      this.getAllClients();
      this.loadHistoryInterventions();
      this.searchAffaires();
    };

    const typeKey = type.toLowerCase();
    if (typeKey === 'secteur') {
      this.secteurService.getRecordDetails(id).subscribe({ next: handleSuccess });
    } else if (typeKey === 'habitation') {
      this.habitationService.getRecordDetails(id).subscribe({ next: handleSuccess });
    } else {
      this.clientsService.getRecordDetails(id).subscribe({ next: handleSuccess });
    }
  }

  getAllClients(page: number = this.clientsPage) {
    this.clientsPage = page;
    this.clientsService.getClientsByParentWithDetails(
      this.id,
      this.client.type_client,
      this.clientsPage,
      this.clientsLimit,
      ''
    ).subscribe((result: any) => {
      this.clientsTotal = result.total;
      this.clients = (result.data || []).map((c: any) => ({
        ...c,
        contacts: c.contacts || []
      }));
    });
  }

  loadHistoryInterventions(page: number = this.historyPage) {
    this.historyPage = page;
    this.clientsService.getByClient(this.id, this.historyPage, this.historyLimit, '')
      .then(res => {
        this.iHistory = res.data;
        this.historyTotal = res.total;
      })
      .catch(err => console.error('Erreur interventions:', err));
  }

  loadHistoriqueAffaire(page: number = this.affairesPage) {
    this.affairesPage = page;
    this.clientsService.getAffairesByClient(
      this.id,
      this.affairesPage,
      this.affairesLimit,
      this.affairesSearch
    ).subscribe({
      next: (res: any) => {
        this.affaires = res.affaires || [];
        this.affairesTotal = res.total || 0;
      }
    });
  }

  // --- ACTIONS ---

  saveNote() {
    if (!this.client?.note?.trim()) return;

    const serviceMap: any = {
      'agence': this.agencesService,
      'organisation': this.organisationsService,
      'particulier': this.particuliersService,
      'secteur': this.secteurService,
      'habitation': this.habitationService
    };

    const service = serviceMap[this.client.type_client];
    if (service) {
      service.updateNote(this.id, this.client.note).subscribe({
        next: () => alert('✅ Note enregistrée'),
        error: (err: any) => console.error('Erreur note:', err)
      });
    }
  }

  deleteClient(id: number) {
    const target = this.clients.find(c => c.id === id);
    if (!target || !confirm('Voulez-vous vraiment supprimer cet élément ?')) return;

    const type = target.type_client?.toLowerCase();
    const service = (type === 'secteur') ? this.secteurService :
      (type === 'habitation') ? this.habitationService :
        this.clientsService;

    service.delete(id).subscribe(() => {
      this.getAllClients();
      alert("🗑️ Supprimé avec succès");
    });
  }

  // --- MODALS ---

  addChilderClient() {
    if (this.modalSave) {
      // Gestion des IDs spécifiques selon le type (client_id vs id)
      const parentId = ['organisation', 'particulier', 'agence'].includes(this.client.type_client)
        ? this.client.client_id : this.client.id;
      this.modalSave.addChilderClient(this.client.type_client, parentId);
    }
  }

  // editClient(client: any) {
  //   console.log("***", client, this.client);
  //   client= { ..., type_parant: this.client.type};
  //   this.modalSave?.editClient(client);
  // }

  editClient(client: any) {
    // 1. Utilisation correcte du spread operator (...)
    // 2. Correction de la faute de frappe 'type_parant' -> 'type_parent' (si applicable)
    const clientToEdit = {
      ...client,
      type_parent: this.client.type_client
    };
    
    // 3. Appel de la méthode sur la modal avec le nouvel objet
    this.modalSave?.editClient(clientToEdit);
  }

  openInterventionModal(item: any) {
    this.selectedIntervention = item;
    const modalEl = document.getElementById('interventionDetailModal');
    if (modalEl) {
      const modal = new bootstrap.Modal(modalEl);
      modal.show();
    }
  }

  // --- NAVIGATION & PAGINATION ---

  goToStep(step: NavStep) {
    this.router.navigate(['/clients/details', step.id], { queryParams: { type: step.type } });
  }

  goToRoot() {
    this.navService.reset();
    this.router.navigate(['/clients/list']);
  }

  viewDetails(client: any) {
    this.router.navigate(['/clients/details', client.id], { queryParams: { type: client.type_client } });
  }

  resetPagination() {
    this.clientsPage = 1;
    this.historyPage = 1;
    this.affairesPage = 1;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Getters pagination Affaires
  get affairesTotalPages(): number { return Math.ceil(this.affairesTotal / this.affairesLimit); }

  searchAffaires() { this.affairesPage = 1; this.loadHistoriqueAffaire(); }

  nextAffairesPage() { if (this.affairesPage < this.affairesTotalPages) this.loadHistoriqueAffaire(this.affairesPage + 1); }

  prevAffairesPage() { if (this.affairesPage > 1) this.loadHistoriqueAffaire(this.affairesPage - 1); }

  nextHistoryPage() { if (this.historyPage * this.historyLimit < this.historyTotal) this.loadHistoryInterventions(this.historyPage + 1); }

  prevHistoryPage() { if (this.historyPage > 1) this.loadHistoryInterventions(this.historyPage - 1); }

  nextClientsPage() { if (this.clientsPage * this.clientsLimit < this.clientsTotal) this.getAllClients(this.clientsPage + 1); }

  prevClientsPage() { if (this.clientsPage > 1) this.getAllClients(this.clientsPage - 1); }
}