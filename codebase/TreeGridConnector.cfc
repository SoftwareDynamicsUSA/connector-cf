<cfcomponent namespace="TreeGridConnector" extends="GridConnector" hint="Connector for dhtmlxTreeGrid">
	<cfscript>
		variables.id_swap = structNew();
	</cfscript>	
	<cffunction name="init" access="public" returntype="any" hint="Here initilization of all Masters occurs, execution timer initialized">
		<cfargument name="res" type="string" required="yes" hint="db connection resource">
		<cfargument name="type" type="string" required="no" default="" hint="string , which hold type of database ( MySQL or Postgre ), optional, instead of short DB name, full name of DataWrapper-based class can be provided">
		<cfargument name="item_type" type="string" required="no" default="" hint="name of class, which will be used for item rendering, optional, DataItem will be used by default">
		<cfargument name="data_type" type="string" required="no" default="" hint="name of class which will be used for dataprocessor calls handling, optional, DataProcessor class will be used by default. ">
		<cfset var local = structNew()>
		<cfif not len(ARGUMENTS.item_type)>
			<cfset ARGUMENTS.item_type="TreeGridDataItem">	
		</cfif>
		<cfif not len(ARGUMENTS.data_type)>
			<cfset ARGUMENTS.data_type="TreeGridDataProcessor">
		</cfif>
		<cfset super.init(ARGUMENTS.res,ARGUMENTS.type,ARGUMENTS.item_type,ARGUMENTS.data_type)>
		<cfset local.ar = ArrayNew(1)>
		<cfset local.ar[1] = this>
		<cfset local.ar[2] = "parent_id_correction_a">
		<cfset this.event.attach("afterInsert",local.ar)>
		<cfset local.ar = ArrayNew(1)>
		<cfset local.ar[1] = this>
		<cfset local.ar[2] = "parent_id_correction_b">
		<cfset this.event.attach("beforeProcessing",local.ar)>
		<cfreturn this>
	</cffunction>
	
	<cffunction name="parent_id_correction_a" access="public" returntype="any" hint="store info about ID changes during insert operation">
		<cfargument name="dataAction" type="any" required="yes" hint="data action object during insert operation">
		<cfset variables.id_swap[ARGUMENTS.dataAction.get_id()]=ARGUMENTS.dataAction.get_new_id()>
	</cffunction>	
	<cffunction name="parent_id_correction_b" access="public" returntype="any" hint="update ID if it was affected by previous operation">
		<cfargument name="dataAction" type="any" required="yes" hint="data action object, before any processing operation">
		<cfset var relation = variables.config.relation_id["db_name"]>
		<cfset var value = ARGUMENTS.dataAction.get_value(relation)>
		<cfif structKeyExists(variables.id_swap,value)>
			<cfset ARGUMENTS.dataAction.set_value(relation,variables.id_swap[value])>
		</cfif>	
	</cffunction>	

	<cffunction name="parse_request" access="public" returntype="any" hint="process treegrid specific options in incoming request">
		<cfset super.parse_request()>
		<cfif isDefined("URL.id")>
			<cfset variables._request.set_relation(URL.id)>
		<cfelse>
			<cfset variables._request.set_relation("0")>
		</cfif>	
		<!--- netralize default reaction on dyn. loading mode--->
		<cfset variables._request.set_limit(0,0)> 
	</cffunction>

	<cffunction name="render_set" access="public" returntype="any" hint="process treegrid specific options in incoming request">
		<cfargument name="res" type="query" required="yes">
		<cfset var local = structNew()>
		<cfset local.output="">
		<cfif not isDefined("this.sub_requestO")>
			<cfset this.sub_requestO = createObject("component","DataRequestConfig")>	
		</cfif>
		
		
		<cfloop query="ARGUMENTS.res">
			<cfset local.data=this.sql.get_next(ARGUMENTS.res,ARGUMENTS.res.currentRow)>
			<cfset local.data = CreateObject("component",names["item_class"]).init(local.data,variables.config,ARGUMENTS.res.currentRow)>
			<cfset this.event.trigger("beforeRender",local.data)>
			
			<!----
			//there is no info about child elements, 
			//if we are using dyn. loading - assume that it has,
			//in normal mode juse exec sub-render routine		
			--->
			
			<cfif local.data.has_kids()eq -1 AND variables.dload>
				<cfset local.data.set_kids(1)>
			</cfif>	
			<cfset local.output = local.output & local.data.to_xml_start()>
			<cfif local.data.has_kids() eq -1 OR (local.data.has_kids() AND NOT variables.dload)>
				<cfset local.sub_request = this.sub_requestO.init(variables._request)>
				<cfset local.sub_request.set_relation(local.data.get_id())>
				<cfset local.output = local.output & render_set(this.sql.do_select(local.sub_request))>
			</cfif>
			<cfset local.output = local.output & local.data.to_xml_end()>
		</cfloop>
		<cfreturn local.output>
	</cffunction>
	<cffunction name="xml_start" access="public" returntype="string">
		<cfreturn "<rows parent='" & variables._request.get_relation() & "'>">
	</cffunction>
</cfcomponent>			