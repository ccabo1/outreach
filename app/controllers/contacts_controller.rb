class ContactsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_contact, only: [:show, :edit, :update, :destroy]
    before_action :owned_contact, only: [:show, :edit, :update, :destroy]

    def index
        # Determine contacts
        if params[:search]
            @contacts = Contact.where('lower(name) LIKE ?', "%#{params[:search]}%".downcase).or(Contact.where('lower(company) LIKE ?', "%#{params[:search]}%".downcase))
        elsif (current_user and params[:long_term])
            # For long term mentors specifically
            @contacts = current_user.contacts.where(:long_term)
        elsif (current_user)
            # Default show page
            @contacts = current_user.contacts
            @mentors = current_user.contacts.where(long_term: true).includes(:reaches).order("reaches.time desc")
            @uninterested = current_user.contacts.where(uninterested: true)
            interested = current_user.contacts.where(uninterested: false).or(current_user.contacts.where(uninterested: nil))
            @short_term = current_user.contacts.where(long_term: false).or(current_user.contacts.where(long_term: nil)).merge(interested)
        else
            # If the user is not signed in, they can see no contacts
            @contacts = Contact.none
        end

        # Determined reaches and responses
        @reaches = Reach.none
        @responses = Reach.none

        # Reaches and responses are determined depending on the scope of contacts
        @contacts.each do |c|
            @reaches = @reaches.or(c.reaches.where(response: false))
            @responses = @responses.or(c.reaches.where(response: true))
        end
    end

    def new
        @contact = current_user.contacts.build
    end

    def create
        @contact = current_user.contacts.build(contact_params)

        if @contact.save
            flash[:success] = "Contact successfully created."
            redirect_to @contact
        else
            flash.now[:alert] = "Failed to add contact. Please check the form."
            render :new
        end
    end

    def show
        @reaches = @contact.reaches.where(response: false)
        @responses = @contact.reaches.where(response: true)
        @history = @contact.reaches.sort_by &:time
    end

    def edit
    end

    def update
        if @contact.update(contact_params)
            flash[:success] = "Contact updated."
            redirect_to(contact_path(@contact))
        else
            flash.now[:alert] = "Update failed. Please check the form."
            render :edit
        end
    end

    def destroy
        @contact.destroy
        flash[:success] = "Contact successfully deleted."
        redirect_to root_path
    end

    private

    def contact_params
        params.require(:contact).permit(:name, :email, :secondary_email, :cell, :work, :company, :company_details, :role, :linkedin, :facebook, :notes, :long_term, :uninterested)
    end

    def set_contact
        @contact = Contact.find(params[:id])
    end

    def owned_contact
        unless current_user == @contact.user
            flash[:alert] = "Contact does not belong to you"
            redirect_to root_path
        end
    end
end
