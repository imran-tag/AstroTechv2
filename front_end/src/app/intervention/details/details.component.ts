import { Component, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { InterventionService } from '../../_services/affaires/intervention.service';
import { TechnicienService } from '../../_services/techniciens/technicien.service';
import { EquipeTechniciensService } from '../../_services/techniciens/equipe-techniciens.service';
import { ModalSaveComponent } from '../modal-save/modal-save.component';

@Component({
  selector: 'app-details',
  standalone: true,
  imports: [CommonModule, FormsModule, ModalSaveComponent],
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {
  @ViewChild('modalSave') modalSave!: ModalSaveComponent;
  
  intervention: any = null;
  interventionId!: number;
  interventionItems: any[] = []; // Initialisé en tableau vide pour le *ngIf

  constructor(
    private interventionService: InterventionService,
    private technicienService: TechnicienService,
    private equipeTechniciensService: EquipeTechniciensService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.interventionId = Number(this.route.snapshot.paramMap.get('id'));
    if (this.interventionId) {
      this.loadData();
      this.loadHistorique();
    }
  }

  loadData() {
    this.interventionService.getItemById(this.interventionId).subscribe({
      next: (res) => {
        this.intervention = res;
        // Sécurité pour les listes
        if (this.intervention) {
          this.intervention.techniciens = this.intervention.techniciens || [];
        }
      },
      error: (err) => console.error('Erreur chargement intervention', err)
    });
  }

  loadHistorique() {
    this.interventionService.getInterventionDetails(this.interventionId).subscribe({
      next: (data) => {
        this.buildTimeline(data);
      },
      error: (err) => console.error('Erreur historique', err)
    });
  }

  /**
   * Construit la timeline chronologique
   */
  buildTimeline(data: any) {
    if (!data) return;
    let items: any[] = [];

    // 1. Gestion si les données arrivent groupées par date (votre second code)
    const sortedDates = Object.keys(data).filter(key => Array.isArray(data[key])).sort((a, b) => 
      new Date(a).getTime() - new Date(b).getTime()
    );

    if (sortedDates.length > 0) {
      sortedDates.forEach(date => {
        data[date].forEach((event: any) => {
          items.push(this.mapEventToItem(event));
        });
      });
    } else {
      // 2. Gestion si les données sont à plat (votre premier code)
      if (data.photos?.before) {
        data.photos.before.forEach((p: any) => items.push({ date: p.captured_at, type: 'photo', title: 'AVANT TRAVAUX', content: [p.url] }));
      }
      if (data.signatures?.client) {
        items.push({ date: data.signatures.client.signed_at, type: 'signature', title: 'SIGNATURE CLIENT', content: [`data:image/png;base64,${data.signatures.client.signature_data}`] });
      }
      // Ajoutez ici les autres mappings selon votre structure API
    }

    // Tri final par date
    this.interventionItems = items.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  }

  private mapEventToItem(event: any) {
    let item: any = { date: event.event_date, type: 'text', title: event.event_type, content: event.description };
    
    if (event.event_type === 'PHOTO') {
      item.type = 'photo';
      item.content = [event.description]; 
      item.title = event.sub_type === 'before' ? 'PHOTO AVANT' : 'PHOTO APRES';
    } else if (event.event_type === 'SIGNATURE') {
      item.type = 'signature';
      item.content = [event.description]; // Base64
    } else if (event.event_type === 'WORKFLOW') {
      item.type = 'table';
      item.content = ['Trajet Aller', 'Intervention', 'Trajet Retour'];
    }
    return item;
  }

  formatEtat(etat: string | null): string {
    if (!etat) return 'Non défini';
    return etat.replace(/_/g, ' ').toLowerCase().replace(/^\w/, c => c.toUpperCase());
  }

  getRealInterventionDuration(): string {
    if (this.intervention?.date_debut_intervention && this.intervention?.date_fin_intervention) {
      const start = new Date(this.intervention.date_debut_intervention);
      const end = new Date(this.intervention.date_fin_intervention);
      const diffMs = end.getTime() - start.getTime();
      const hours = Math.floor(diffMs / 3600000);
      const mins = Math.floor((diffMs % 3600000) / 60000);
      return `${hours}h ${mins}min`;
    }
    return '-';
  }

  editIntervention(id: number) { this.router.navigate(['/interventions/edit', id]); }
  
  deleteIntervention(id: number) {
    if (confirm("Supprimer cette intervention ?")) {
      this.interventionService.delete(id).subscribe(() => this.router.navigate(['/interventions/list']));
    }
  }

  modePlanification(interv: any) {
    this.modalSave?.initializeModal(interv);
  }

  editPlanning() {
    this.router.navigate(['/interventions/planning']);
  }

  pad(value: number): string {
    return value.toString().padStart(2, '0');
  }

}