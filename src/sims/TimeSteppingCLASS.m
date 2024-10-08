classdef TimeSteppingCLASS
    %TIMESTEPPINGCLASS Summary of this class goes here
    %   Detailed explanation goes here

    % Public Properties
    properties (SetAccess = public, GetAccess = public)
        % Parameters
        tSTART = 0;
        tMAX   = 60;
        dt     = 0.05;
        % Output:
        t_out    = [];
        x_out    = [];
        y_out    = [];
        dxdt_out = [];we
        u_out  = [];
        debug = [];
    end
    
    % Private Properties
    properties (SetAccess = private, GetAccess = private)
        model;        % A model object
        controller;
        trajectory;
        observer;
        className;
        folderPath;
    end

    methods
        function obj = TimeSteppingCLASS(model, trajectory, controller, observer)
            % Constructor creates a simulation for a specific model
            obj.model      = model;
            obj.controller = controller;
            obj.trajectory = trajectory;
            obj.observer   = observer;
            obj.className  = class(obj);
            [obj.folderPath] = fileparts(which(obj.className));
        end
        
        function obj = Save(obj, file_name)
            data = [obj.t_out', obj.x_out', obj.u_out'];

            data = round(data, 6);

            output = [num2cell(data)];
            
            fileName = append(file_name, '.csv');

            filePath = append(obj.folderPath, '/', fileName);

            writecell(output, filePath); % introduced in Matlab 2019a
        end

        function obj = Run(obj, q0)
            obj.t_out    = linspace(obj.tSTART, obj.tMAX, (1/obj.dt) * obj.tMAX);
            nt           = size(obj.t_out,2);
            obj.x_out    = zeros(obj.model.nx,nt);
            obj.y_out    = zeros(obj.model.nx,nt);

            % Initialize time stepping:
            obj.x_out(:,1)    = q0;
            obj.y_out(:,1)    = q0;

            obj.u_out = zeros(2,nt);
            obj.debug = zeros(2, nt);
            obj.controller = obj.controller.Init();

            for i = 1:size(obj.t_out,2)
                yM = obj.y_out(:, i);
                uM = obj.u_out(:, i);
                
                % Controller
                [status, obj.u_out(:,i), obj.controller] = obj.controller.Loop(yM, uM, i);
                
                if ~status
                    obj.u_out(:,i) = zeros(2, 1);
                end

                % Update model
                xM = obj.model.Function(obj.x_out(:, i), obj.u_out(:,i), obj.dt, obj.model.p);
                
                % Add observer
                yM = obj.observer.Observe(xM);
                
                if i < length(obj.t_out)
                    obj.x_out(:, i+1) = xM;
                    obj.y_out(:, i+1) = yM;
                end
            end
        end
    end
end

