import { Component, Renderer2, EventEmitter, Output } from '@angular/core';
import { lastValueFrom } from 'rxjs';
import { SharedModule } from '../../_globale/shared/shared.module';
import { ClientsService } from '../../_services/clients/clients.service';
import { AdressesService } from '../../_services/clients/adresses.service';
import { AdresseEmailService } from '../../_services/clients/adresse-email.service';
import { AgencesService } from '../../_services/clients/agences.service';
import { ContactsService } from '../../_services/clients/contacts.service';
import { NumTelService } from '../../_services/clients/num-tel.service';
import { OrganisationsService } from '../../_services/clients/organisations.service';
import { ParticuliersService } from '../../_services/clients/particuliers.service';
import { SecteurService } from '../../_services/clients/secteur.service';
import { HabitationService } from '../../_services/clients/habitation.service';
import * as bootstrap from 'bootstrap';
import { ActivatedRoute } from '@angular/router';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { debounceTime, switchMap, catchError, startWith, map, distinctUntilChanged } from 'rxjs/operators';
import { Observable, of } from 'rxjs'; // Vérifie bien l'import de 'of'
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-modal-save',
  standalone: true, // Assurez-vous que c'est bien un composant standalone
  imports: [
    CommonModule,          // <-- Indispensable pour | async et *ngIf
    ReactiveFormsModule,   // <-- Indispensable pour [formControl]
    SharedModule,
    MatFormFieldModule,
    MatInputModule,
    MatAutocompleteModule,
  ],
  templateUrl: './modal-save.component.html',
  styleUrls: ['./modal-save.component.css']
})
export class ModalSaveComponent {

  @Output() clientAdded = new EventEmitter<any>();
  modalInstance: any;

  constructor(
    private clientsService: ClientsService,
    private adressesService: AdressesService,
    private adresseEmailService: AdresseEmailService,
    private agencesService: AgencesService,
    private contactsService: ContactsService,
    private numTelService: NumTelService,
    private organisationsService: OrganisationsService,
    private particuliersService: ParticuliersService,
    private secteurService: SecteurService,
    private habitationService: HabitationService,
    private renderer: Renderer2,
    private route: ActivatedRoute
  ) {
    this.addItem('tous');
    this.filteredOptions('');
  }

  // Variables principales
  singleAdresse: any = this.getEmptyAdresse();
  singleClient: any = { id: null, numero: null, compte: null, parent_id: null };
  singleParticulier: any = { id: null, nom_complet: null, email: null, telephone: null, adresse_id: null, client_id: null };
  singleAgence: any = { id: null, client_id: null, nom_agence: null, adresse_id: null };
  singleOrganisation: any = { id: null, client_id: null, nom_entreprise: null };
  singleHabitation: any = { id: null, reference: null, surface: null, adresse_id: null, secteur_id: null, agence_id: null, organisation_id: null, particulier_id: null };
  singleSecteur: any = { id: null, reference: null, nom: null, description: null, adresse_id: null, agence_id: null, organisation_id: null, parent_id: null };

  // Contact
  singleContact: any = {
    id: null, nom_complet: null, poste: null, date_du: null, date_au: null,
    date_duString: null, date_auString: null, memo_note: null, client_id: null, secteur_id: null, habitation_id: null,
    listEmails: [], listTels: []
  };
  singleAdresseEmail: any = { id: null, email: null, type: 'personnel', contact_id: null };
  singleNumTel: any = { id: null, tel: null, type: 'personnel', contact_id: null };

  listContacts: any[] = [];
  listEmails: any[] = [];
  listTels: any[] = [];

  isFirstVisible = false;
  isContactValidate = true;
  isEditMode = false;

  type_client: string = '';
  options = [
    { value: 'organisation', label: 'Organisation' },
    { value: 'agence', label: 'Agence' },
    { value: 'particulier', label: 'Particulier' },
    { value: 'secteur', label: 'Secteur' },
    { value: 'habitation', label: 'Habitation' }
  ];

  filteredOptionsList: any[] = [];
  parentClient: any = { type: '', id: -1 };
  isVisibleListClient: boolean = false;
  clients: any = [];

  filteredOptions(type: string) {
    let filtered: any[] = [];
    switch (type) {
      case 'agence': filtered = this.options.filter(opt => ['agence', 'secteur', 'habitation'].includes(opt.value)); break;
      case 'secteur': filtered = this.options.filter(opt => ['secteur', 'habitation'].includes(opt.value)); break;
      case 'particulier':
      case 'habitation': filtered = this.options.filter(opt => ['habitation'].includes(opt.value)); break;
      default: filtered = this.options.filter(opt => ['organisation', 'agence', 'particulier'].includes(opt.value));
    }
    this.filteredOptionsList = filtered;
    this.type_client = this.filteredOptionsList[0].value; // sélection automatique du premier
  }

  addItem(type: string) {
    if (type === 'tous') { this.listEmails.push({ ...this.singleAdresseEmail }); this.listTels.push({ ...this.singleNumTel }); }
    else if (type === 'email') this.listEmails.push({ ...this.singleAdresseEmail });
    else this.listTels.push({ ...this.singleNumTel });
  }

  async removeItem(type: string, index: number) {
    if (type === 'email') this.listEmails.splice(index, 1);
    else if (type === 'tel') this.listTels.splice(index, 1);
    else {
      const contact = this.listContacts[index];
      // Message de confirmation
      const confirmed = confirm(`Voulez-vous vraiment supprimer le contact "${contact.nom_complet}" ?`);
      if (!confirmed) return; // Annule la suppression si l'utilisateur clique sur "Annuler"
      // Si le contact existe en base → suppression API
      if (this.isEditMode && contact.id) {
        try {
          await lastValueFrom(this.contactsService.delete(contact.id));
          this.clientAdded.emit();
          console.log('Contact supprimé en base :', contact.id);
        } catch (err) {
          console.error('Erreur suppression contact :', err);
          alert("Erreur lors de la suppression du contact.");
          return;
        }
      }
      // Suppression du front
      this.listContacts.splice(index, 1);
    }

  }

  /** Toggle formulaire contact */
  toggleDiv() { this.isFirstVisible = !this.isFirstVisible; }

  /** Ajoute un contact dans la liste */
  addContact() {
    if (this.singleContact.nom_complet && this.singleContact.poste) {
      this.listContacts.push({
        ...this.singleContact,
        listEmails: [...this.listEmails],
        listTels: [...this.listTels]
      });
      this.toggleDiv();
      this.clearContact();
      this.isContactValidate = true;
    } else {
      this.isContactValidate = false;
    }
  }

  clearContact() {
    this.singleContact = {
      id: null, nom_complet: null, poste: null, date_du: null, date_au: null,
      date_duString: null, date_auString: null, memo_note: null, client_id: null, listEmails: [], listTels: []
    };
    this.listEmails = [{ ...this.singleAdresseEmail }];
    this.listTels = [{ ...this.singleNumTel }];
  }

  /** Sauvegarde client et contacts */
  async save() {
    // 🔹 Convertir les dates des contacts
    this.listContacts.forEach(c => {
      if (c.date_duString) c.date_du = c.date_duString;
      if (c.date_auString) c.date_au = c.date_auString;
    });

    // 🔹 Helper pour vérifier si l’adresse contient des informations
    const hasAdresseInfo = (adresse: any): boolean => {
      if (!adresse) return false;
      return !!(
        adresse.adresse?.trim() ||
        adresse.code_postal?.trim() ||
        adresse.ville?.trim() ||
        adresse.province?.trim() ||
        adresse.pays?.trim() ||
        adresse.etage?.trim() ||
        adresse.appartement_local?.trim() ||
        adresse.batiment?.trim() ||
        adresse.interphone_digicode?.trim() ||
        adresse.escalier?.trim() ||
        adresse.porte_entree?.trim()
      );
    };

    try {
      let parentIdToPass: any;

      // 🔹 Mode édition
      if (this.isEditMode) {
        if (['agence', 'organisation', 'particulier'].includes(this.type_client)) {
          await lastValueFrom(this.clientsService.update(this.singleClient));
        }

        switch (this.type_client) {
          case 'organisation':
            if (hasAdresseInfo(this.singleAdresse)) {
              if (this.singleAdresse.id) {
                await lastValueFrom(this.adressesService.update(this.singleAdresse));
              } else {
                const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
                this.singleAdresse.id = resAdresse.data.id;
                this.singleOrganisation.adresse_id = resAdresse.data.id;
              }
            }
            await lastValueFrom(this.organisationsService.update(this.singleOrganisation));
            parentIdToPass = this.singleClient.id;
            break;

          case 'particulier':
            if (hasAdresseInfo(this.singleAdresse)) {
              if (this.singleAdresse.id) {
                await lastValueFrom(this.adressesService.update(this.singleAdresse));
              } else {
                const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
                this.singleAdresse.id = resAdresse.data.id;
                this.singleParticulier.adresse_id = resAdresse.data.id;
              }
            }
            await lastValueFrom(this.particuliersService.update(this.singleParticulier));
            parentIdToPass = this.singleClient.id;
            break;

          case 'agence':
            if (hasAdresseInfo(this.singleAdresse)) {
              if (this.singleAdresse.id) {
                await lastValueFrom(this.adressesService.update(this.singleAdresse));
              } else {
                const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
                this.singleAdresse.id = resAdresse.data.id;
                this.singleAgence.adresse_id = resAdresse.data.id;
              }
            }
            await lastValueFrom(this.agencesService.update(this.singleAgence));
            parentIdToPass = this.singleClient.id;
            break;

          case 'secteur':
            if (hasAdresseInfo(this.singleAdresse)) {
              if (this.singleAdresse.id) {
                await lastValueFrom(this.adressesService.update(this.singleAdresse));
              } else {
                const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
                this.singleAdresse.id = resAdresse.data.id;
                this.singleSecteur.adresse_id = resAdresse.data.id;
              }
            }
            await lastValueFrom(this.secteurService.update(this.singleSecteur));
            parentIdToPass = this.singleSecteur.id;
            break;

          case 'habitation':
            if (hasAdresseInfo(this.singleAdresse)) {
              if (this.singleAdresse.id) {
                await lastValueFrom(this.adressesService.update(this.singleAdresse));
              } else {
                const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
                this.singleAdresse.id = resAdresse.data.id;
                this.singleHabitation.adresse_id = resAdresse.data.id;
              }
            }
            await lastValueFrom(this.habitationService.update(this.singleHabitation));
            parentIdToPass = this.singleHabitation.id;
            break;
        }

      } else {
        // 🔹 Mode création
        let clientId: number | undefined;

        if (['organisation', 'particulier', 'agence'].includes(this.type_client)) {
          if (this.parentClient?.type) this.singleClient.parent_id = this.parentClient.id;
          const res: any = await lastValueFrom(this.clientsService.create(this.singleClient));
          clientId = this.singleClient.id = res.data.id;
        }

        switch (this.type_client) {
          case 'organisation':
            this.singleOrganisation.client_id = clientId;
            if (hasAdresseInfo(this.singleAdresse)) {
              const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
              this.singleAdresse.id = resAdresse.data.id;
              this.singleOrganisation.adresse_id = resAdresse.data.id;
            }
            const resOrg: any = await lastValueFrom(this.organisationsService.create(this.singleOrganisation));
            this.singleOrganisation.id = resOrg.data.id;
            parentIdToPass = clientId;
            break;

          case 'particulier':
            this.singleParticulier.client_id = clientId;
            if (hasAdresseInfo(this.singleAdresse)) {
              const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
              this.singleAdresse.id = resAdresse.data.id;
              this.singleParticulier.adresse_id = resAdresse.data.id;
            }
            const resPart: any = await lastValueFrom(this.particuliersService.create(this.singleParticulier));
            this.singleParticulier.id = resPart.data.id;
            parentIdToPass = clientId;
            break;

          case 'agence':
            this.singleAgence.client_id = clientId;
            if (hasAdresseInfo(this.singleAdresse)) {
              const resAdresse: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
              this.singleAdresse.id = resAdresse.data.id;
              this.singleAgence.adresse_id = resAdresse.data.id;
            }
            const resAgence: any = await lastValueFrom(this.agencesService.create(this.singleAgence));
            this.singleAgence.id = resAgence.data.id;
            parentIdToPass = clientId;
            break;

          case 'secteur':
            if (hasAdresseInfo(this.singleAdresse)) {
              const resAdresseS: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
              this.singleAdresse.id = resAdresseS.data.id;
              this.singleSecteur.adresse_id = resAdresseS.data.id;
            }
            if (this.parentClient?.type === 'agence') this.singleSecteur.agence_id = this.parentClient.id;
            else if (this.parentClient?.type === 'organisation') this.singleSecteur.organisation_id = this.parentClient.id;
            else if (this.parentClient?.type === 'secteur') this.singleSecteur.parent_id = this.parentClient.id;
            const resSecteur: any = await lastValueFrom(this.secteurService.create(this.singleSecteur));
            this.singleSecteur.id = resSecteur.data.id;
            parentIdToPass = this.singleSecteur.id;
            break;

          case 'habitation':
            if (hasAdresseInfo(this.singleAdresse)) {
              const resAdresseH: any = await lastValueFrom(this.adressesService.create(this.singleAdresse));
              this.singleAdresse.id = resAdresseH.data.id;
              this.singleHabitation.adresse_id = resAdresseH.data.id;
            }
            if (this.parentClient?.type === 'agence') this.singleHabitation.agence_id = this.parentClient.id;
            else if (this.parentClient?.type === 'organisation') this.singleHabitation.organisation_id = this.parentClient.id;
            else if (this.parentClient?.type === 'secteur') this.singleHabitation.secteur_id = this.parentClient.id;
            else if (this.parentClient?.type === 'particulier') this.singleHabitation.particulier_id = this.parentClient.id;
            const resHab: any = await lastValueFrom(this.habitationService.create(this.singleHabitation));
            this.singleHabitation.id = resHab.data.id;
            parentIdToPass = this.singleHabitation.id;
            break;
        }
      }

      // 🔹 Sauvegarder les contacts
      if (parentIdToPass) await this.saveAllContacts(parentIdToPass);

      // 🔹 Préparer le payload
      const payload = {
        client_id: this.singleClient?.id,
        id: parentIdToPass,
        type_client: this.type_client,
        nom_client: this.getNomClientByType(),
        note: this.singleClient?.note,
        adresse: hasAdresseInfo(this.singleAdresse) ? this.singleAdresse : null,
        contacts: this.listContacts,
      };

      this.clientAdded.emit(payload);

      // 🔹 Nettoyer et fermer
      this.clear();
      this.closeModal();
      alert('Client enregistré avec succès !');

    } catch (err) {
      console.error('Erreur lors de la sauvegarde du client :', err);
      alert('Une erreur est survenue lors de la sauvegarde du client.');
    }
  }


  getNomClientByType(): string | null {
    switch (this.type_client) {

      case 'particulier':
        return this.singleParticulier?.nom_complet || null;

      case 'agence':
        return this.singleAgence?.nom_agence || null;

      case 'organisation':
        return this.singleOrganisation?.nom_entreprise || null;

      case 'secteur':
        return this.singleSecteur?.nom || null;

      case 'habitation':
        return this.singleHabitation?.nom || null;

      default:
        return this.singleClient?.nom_client || null;
    }
  }

  /** Sauvegarde tous les contacts et leurs emails/téléphones **/
  async saveAllContacts(parentId: number) {
    for (const contact of this.listContacts) {
      if (['organisation', 'particulier', 'agence'].includes(this.type_client)) contact.client_id = parentId;
      else if (this.type_client === 'secteur') contact.secteur_id = parentId;
      else if (this.type_client === 'habitation') contact.habitation_id = parentId;

      try {
        const existing: any = await lastValueFrom(
          this.contactsService.getByNameAndPoste({
            type: this.type_client,
            id: parentId,
            nom_complet: contact.nom_complet,
            poste: contact.poste
          })
        );

        if (existing?.data) { contact.id = existing.data.id; await lastValueFrom(this.contactsService.update(contact)); }
        else { const result: any = await lastValueFrom(this.contactsService.create(contact)); contact.id = result.data.id; }

        for (const email of contact.listEmails) {
          const existsEmail: any = await lastValueFrom(this.adresseEmailService.getByEmailAndContact(contact.id, email.email));
          if (!existsEmail?.data) await lastValueFrom(this.adresseEmailService.create({ contact_id: contact.id, client_id: contact.client_id, email: email.email, type: email.type }));
        }

        for (const tel of contact.listTels) {
          const existsTel: any = await lastValueFrom(this.numTelService.getByTelAndContact(contact.id, tel.tel));
          if (!existsTel?.data) await lastValueFrom(this.numTelService.create({ contact_id: contact.id, client_id: contact.client_id, tel: tel.tel, type: tel.type }));
        }

      } catch (err) { console.error('Erreur lors de la sauvegarde du contact :', err); }
    }
  }

  /** Initialise une adresse vide */
  getEmptyAdresse() {
    return {
      id: null,
      adresse: '',
      code_postal: '',
      ville: '',
      province: '',
      pays: '',
      etage: '',
      appartement_local: '',
      batiment: '',
      interphone_digicode: '',
      escalier: '',
      porte_entree: '',
      createur_id: null,
      date_creation: null,
      date_modification: null
    };
  }


  /** Réinitialiser le formulaire */
  clear() {
    this.filteredOptions('');

    this.singleClient = { id: null, numero: null, compte: null, parent_id: null };
    this.singleParticulier = { id: null, nom_complet: null, email: null, telephone: null, adresse_id: null, client_id: null };
    this.singleAgence = { id: null, client_id: null, nom_agence: null, adresse_id: null };
    this.singleOrganisation = { id: null, client_id: null, nom_entreprise: null };
    this.singleSecteur = { id: null, reference: null, nom: null, description: null, adresse_id: null, agence_id: null, organisation_id: null, parent_id: null };
    this.singleHabitation = { id: null, reference: null, surface: null, adresse_id: null, secteur_id: null, agence_id: null, organisation_id: null, particulier_id: null };
    this.singleAdresse = this.getEmptyAdresse();
    this.listContacts = [];
    this.listEmails = [];
    this.listTels = [];
    //this.type_client = '';
    this.parentClient = { type: '', id: -1 };
    this.isEditMode = false;

    this.clearContact();
  }

  /** Ouvre le modal */
  openModal() {
    const modalEl = document.getElementById('saveModal');
    if (modalEl) this.modalInstance = new bootstrap.Modal(modalEl, { backdrop: 'static', keyboard: false });
    this.modalInstance.show();
  }


  /** Ferme le modal */
  closeModal() {
    const modalEl = document.getElementById('saveModal');
    if (!modalEl) return;

    // Récupère l'instance existante
    let instance = this.modalInstance || bootstrap.Modal.getInstance(modalEl);
    if (instance) {
      instance.hide();
      this.modalInstance = null;
    }

    // 🔹 Supprimer le backdrop s’il reste
    const backdrops = document.getElementsByClassName('modal-backdrop');
    while (backdrops.length > 0) {
      backdrops[0].parentNode?.removeChild(backdrops[0]);
    }

    // 🔹 Supprimer la classe 'modal-open' du body si elle est restée
    document.body.classList.remove('modal-open');
  }

  /** Modifier un client existant */
  /** Editer un client */
  editClient(client: any) {

    // Récupère la valeur une seule fois au chargement du composant
    //let typeValue = this.route.snapshot.queryParamMap.get('type');
    let typeValue: string = this.route.snapshot.queryParamMap.get('type') ?? '';

    this.isEditMode = true;
    this.isFirstVisible = true;
    this.parentClient = { type: typeValue, id: client.parent_id };
    this.filteredOptions(typeValue);

    // Client principal
    this.singleClient = {
      id: client.id || null,
      numero: client.numero || '',
      compte: client.compte || ''
    };

    // Initialisation selon le type de client
    switch (client.type_client) {
      case 'organisation':
        this.type_client = 'organisation';
        this.singleOrganisation = {
          id: client.organisation_id || client.organisation?.id || null,
          client_id: client.id || null,
          nom_entreprise: client.nom_client || client.organisation?.nom_entreprise || ''
        };
        this.singleAdresse = client.adresse ? { ...client.adresse } : this.getEmptyAdresse();
        break;

      case 'particulier':
        this.type_client = 'particulier';
        this.singleParticulier = {
          id: client.particulier_id || client.particulier?.id || null,
          client_id: client.id || null,
          nom_complet: client.nom_client || client.particulier?.nom_complet || '',
          email: client.email || client.particulier?.email || '',
          telephone: client.telephone || client.particulier?.telephone || '',
          adresse_id: client.adresse?.id || client.particulier?.adresse_id || null
        };
        this.singleAdresse = client.adresse ? { ...client.adresse } : this.getEmptyAdresse();
        break;

      case 'agence':
        this.type_client = 'agence';
        this.singleAgence = {
          id: client.agence_id || client.agence?.id || null,
          client_id: client.id || null,
          nom_agence: client.nom_client || client.agence?.nom_agence || '',
          adresse_id: client.adresse?.id || client.agence?.adresse_id || null
        };
        this.singleAdresse = client.adresse ? { ...client.adresse } : this.getEmptyAdresse();
        break;


      case 'secteur':
        this.type_client = 'secteur';
        // On récupère l'objet secteur s'il existe pour raccourcir les lignes suivantes
        const secteurData = client.secteur;
        this.singleSecteur = {
          id: client.secteur_id ?? secteurData?.id ?? null,
          reference: client.reference ?? secteurData?.reference ?? '',
          nom: client.nom_client ?? secteurData?.nom ?? '',
          description: client.description ?? secteurData?.description ?? '',
          adresse_id: client.adresse?.id ?? secteurData?.adresse_id ?? null,
          agence_id: client.agence_id ?? secteurData?.agence_id ?? null,
          organisation_id: client.organisation_id ?? secteurData?.organisation_id ?? null,
          parent_id: client.parent_id ?? secteurData?.parent_id ?? null
        };
        // Gestion de l'adresse
        this.singleAdresse = client.adresse ? { ...client.adresse } : this.getEmptyAdresse();
        break;

      case 'habitation':
        console.log();

        this.type_client = 'habitation';
        const h = client.habitation; // Alias pour plus de clarté

        this.singleHabitation = {
          id: client.habitation_id ?? h?.id ?? null,
          reference: client.reference ?? h?.reference ?? '',
          surface: client.surface ?? h?.surface ?? null,
          adresse_id: client.adresse?.id ?? h?.adresse_id ?? null,
          secteur_id: client.secteur_id ?? h?.secteur_id ?? null,
          agence_id: client.agence_id ?? h?.agence_id ?? null,
          organisation_id: client.organisation_id ?? h?.organisation_id ?? null,
          particulier_id: client.particulier_id ?? h?.particulier_id ?? null
        };

        this.singleAdresse = client.adresse ? { ...client.adresse } : this.getEmptyAdresse();
        break;

      default:
        this.type_client = 'inconnu';
        this.singleAdresse = this.getEmptyAdresse();
        break;
    }

    // Gestion des contacts et de leurs emails/téléphones
    this.listContacts = client.contacts?.map((c: any) => ({
      ...c,
      date_duString: c.date_du ? c.date_du.substring(0, 10) : null,
      date_auString: c.date_au ? c.date_au.substring(0, 10) : null,
      listEmails: c.listEmails?.length ? [...c.listEmails] : [{ ...this.singleAdresseEmail }],
      listTels: c.listTels?.length ? [...c.listTels] : [{ ...this.singleNumTel }]
    })) || [];

    // Initialisation des listes vides si aucun contact
    if (this.listContacts.length === 0) {
      this.listEmails = [{ ...this.singleAdresseEmail }];
      this.listTels = [{ ...this.singleNumTel }];
    }

    this.openModal();
  }


  /** Ajouter un client enfant (secteur ou habitation) */
  addChilderClient(type: string, id: number) {
    this.parentClient = { type: type, id: id };
    this.filteredOptions(type);
    this.singleClient = { id: null, numero: null, compte: null, parent_id: this.singleClient.id };
    this.openModal();
  }

  /** Tronquer certaines valeurs si nécessaire */
  truncateFields() {
    if (this.singleClient.numero) this.singleClient.numero = this.singleClient.numero.toString().substring(0, 50);
    if (this.singleClient.compte) this.singleClient.compte = this.singleClient.compte.toString().substring(0, 50);
    if (this.singleParticulier.nom_complet) this.singleParticulier.nom_complet = this.singleParticulier.nom_complet.substring(0, 100);
    if (this.singleOrganisation.nom_entreprise) this.singleOrganisation.nom_entreprise = this.singleOrganisation.nom_entreprise.substring(0, 100);
    if (this.singleAgence.nom_agence) this.singleAgence.nom_agence = this.singleAgence.nom_agence.substring(0, 100);
    if (this.singleSecteur.nom) this.singleSecteur.nom = this.singleSecteur.nom.substring(0, 100);
  }


  addZoneIntervention(type: string, id: number) {
    this.parentClient = { type: type, id: id };
    this.isVisibleListClient = true;
    this.filteredOptions(type);
    this.getAllClientsEnfantsByParent(id, type);
  }


  // Charger les clients enfants
  getAllClientsEnfantsByParent(id: number, type: string) {
    this.clientsService.getClientsByParentWithDetails(id, type).subscribe((result: any) => {
      this.clients = result.data;
    });
  }

  addClientByOther() {
    this.isVisibleListClient = false;
    console.log(this.parentClient);
  }

  setZone(client: any) {
    this.clientAdded.emit(client);
    this.closeModal();
  }

  // On définit listAdersse comme un Observable pour l'utiliser avec le pipe | async
  // ✅ À faire :
  listAdersse$: Observable<any[]> = of([]);
  // Le contrôle du champ texte
  adresseCtrl = new FormControl('');
  setupSearch() {
    this.listAdersse$ = this.adresseCtrl.valueChanges.pipe(
      startWith(''),
      debounceTime(300),
      distinctUntilChanged(),
      // On force 'value' à être de type 'any' pour éviter l'erreur 'never' ou '{}'
      switchMap((value: any): Observable<any[]> => {

        // Extraction sécurisée
        const searchTerm = typeof value === 'string' ? value : (value as any)?.adresse;

        if (searchTerm && searchTerm.length > 2) {
          // On précise que getAll retourne un tableau d'any
          return this.adressesService.getAll(searchTerm).pipe(
            catchError(() => of([]))
          );
        } else {
          return of([]);
        }
      })
    );
  }


  displayFn(addr: any): string {
    // Debug : vérifiez ce qui arrive quand vous sélectionnez ou cherchez
    // console.log("Donnée reçue par displayFn :", addr);
    if (addr && typeof addr === 'object') {
      return addr.adresse || ''; // Vérifiez bien que la clé SQL est minuscule 'adresse'
    }
    return addr || '';
  }

  ngOnInit() {
    // On branche l'écouteur d'événements au démarrage
    this.setupSearch();
  }

  onAdresseSelected(event: any) {
    const selectedAddr = event.option.value;
    // On remplit l'objet singleAdresse avec les données reçues
    this.singleAdresse = { ...selectedAddr };
    
  }


}
