module Commontator
  class CommentsController < ApplicationController

    include ThreadsHelper

    before_filter :get_thread, :only => [:index, :new, :create]
    before_filter :setup_comment_variables, :except => [:index, :new, :create]

    # GET /1/comments/new
    def new
      raise SecurityTransgression unless @user.can_read?(@thread)

      @comments = Vote.order_by_votes(@thread.comments)

      @comment = Comment.new
      @comment.thread = @thread
      @comment.creator = @user
      if @thread.commentable_type == 'Message'
        @create_verb = 'Send'
        @comment_name = 'Reply'
      else
        @create_verb = 'Post'
        @comment_name = 'Comment'
      end

      raise SecurityTransgression unless @user.can_create?(@comment)

      respond_to do |format|
        format.html
        format.js
      end
     
    end

    # POST /1/comments
    def create
      raise SecurityTransgression unless @user.can_read?(@thread)

      @comment = Comment.new(params[:comment])
      @comment.thread = @thread
      @comment.creator = @user

      if @thread.commentable_type == 'Message'
        @comment_notice = 'Reply sent.'
        @hide_votes = true
      else
        @comment_notice = 'Comment posted.'
        @show_link = true
      end

      raise SecurityTransgression unless @user.can_create?(@comment)

      respond_to do |format|
        if @comment.save
          @thread.subscribe!(@user)
          @thread.add_unread_except_for(@user)
          flash[:notice] = @comment_notice
          SubscriptionNotifier.comment_created_email(@comment)
          format.html { redirect_to(polymorphic_path([@commentable, :comments])) }
          format.js
        else
          @errors = @comment.errors
          format.html { render :action => 'new' }
          format.js { render :action => 'shared/display_flash' }
        end
      end
    end

    # GET /comments/1
    def show
      raise SecurityTransgression unless @user.can_read?(@comment)

      respond_to do |format|
        format.html # show.html.erb
      end
    end

    # GET /comments/1/edit
    def edit
      raise SecurityTransgression unless @user.can_update?(@comment)

      if @thread.commentable_type == 'Message'
        @comment_name = 'Reply'
      else
        @comment_name = 'Comment'
      end

      respond_to do |format|
        format.html
        format.js
      end
    end

    # PUT /comments/1
    def update
      raise SecurityTransgression unless @user.can_update?(@comment)

      if @thread.commentable_type == 'Message'
        @comment_notice = 'Reply updated.'
      else
        @comment_notice = 'Comment updated.'
      end

      respond_to do |format|
        if @comment.update_attributes(params[:comment])
          flash[:notice] = @comment_notice
          format.html { redirect_to polymorphic_path([@commentable, :comments]) }
          format.js
        else
          format.html { render :action => "edit" }
          format.js
        end
      end
    end

    # DELETE /comments/1
    def destroy
      raise SecurityTransgression unless @user.can_destroy?(@comment)

      @comment.destroy

      respond_to do |format|
        format.html { redirect_to polymorphic_path([@commentable, :comments]) }
        format.js
      end
    end

    protected

    def setup_comment_variables
      @comment = Comment.find(params[:id])
      @thread = @comment.thread
      @commentable = @thread.commentable.becomes(
                       Kernel.const_get(@thread.commentable_type))
    end

  end
end